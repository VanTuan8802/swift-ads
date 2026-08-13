//
//  AppOpenPreload.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//
//  App Open Ad Loader using Ad Preloading V2 (Preview headers)
//  For openResume - shown when app returns from background
//

import Foundation
import UIKit
import GoogleMobileAds
import PreloadPreview

/// App Open Ad Loader using Ad Preloading V2 (Preview headers)
/// Requirements:
/// - GADAppOpenAdPreloader_Preview.h in Bridging Header
/// - Google Mobile Ads SDK version compatible with these preview headers
public final class AppOpenPreload: NSObject, @unchecked Sendable {

    public static let shared = AppOpenPreload()
    private override init() {}

    // MARK: - Config

    public struct Config {
        /// If true, automatically call preload(adUnitId:) when ads are exhausted
        var autoPreloadOnExhausted: Bool = true

        public init() {}
    }

    public var config = Config()

    // MARK: - State

    private let store = PreloadCallbackStore()

    // MARK: - Events (optional)

    public enum Event {
        case preloadStarted(adUnitId: String)
        case preloadAvailable(preloadID: String, responseInfo: ResponseInfo)
        case preloadExhausted(preloadID: String)
        case preloadSkippedExhausted(preloadID: String)
        case preloadFailed(preloadID: String, error: Error)

        case showBlockedInterval(adUnitId: String, remainSeconds: Int)
        case showNotAvailable(adUnitId: String)
        case polledNil(adUnitId: String)

        case willPresent(adUnitId: String)
        case didDismiss(adUnitId: String)
        case failedToPresent(adUnitId: String, error: Error)
    }

    public var onEvent: ((Event) -> Void)?

    // MARK: - Public API
    /// - Parameter bufferSize: Số lượng quảng cáo muốn giữ trong bộ đệm (mặc định 1). Nếu > 0 sẽ tự động preload.
    public func preload(adUnitId: String, bufferSize: Int = 1) {
        store.setBuffer(bufferSize, for: adUnitId)

        let request = Request()
        let cfg = PreloadConfigurationV2(adUnitID: adUnitId, request: request)
        cfg.bufferSize = UInt(bufferSize)

        onEvent?(.preloadStarted(adUnitId: adUnitId))

        AppOpenAdPreloader.shared.preload(
            for: adUnitId,
            configuration: cfg,
            delegate: self
        )
    }

    /// Verify that an ad is available before polling.
    public func isAvailable(adUnitId: String) -> Bool {
        return AppOpenAdPreloader.shared.isAdAvailable(with: adUnitId)
    }

    /// Poll and show the next available app open ad for the given adUnitId.
    ///
    /// - Parameters:
    ///   - adUnitId: App open ad unit id (also used as preloadID)
    ///   - onDismiss: called when ad is dismissed or fails to present
    ///
    /// - Returns: true if a present attempt started; false if blocked/not available.
    @MainActor
    public func show(adUnitId: String,
                     onWillPresent: (() -> Void)? = nil,
                     onDismiss: (() -> Void)? = nil,
                     onFailedToPresent: ((Error) -> Void)? = nil) -> Bool {

        // 1) Ensure available before polling
        guard isAvailable(adUnitId: adUnitId) else {
            onEvent?(.showNotAvailable(adUnitId: adUnitId))
            return false
        }

        // 2) Poll next available ad
        guard let ad = AppOpenAdPreloader.shared.ad(with: adUnitId) else {
            onEvent?(.polledNil(adUnitId: adUnitId))
            return false
        }

        // 3) Track mapping for callbacks
        store.register(ObjectIdentifier(ad),
                       adUnitId: adUnitId,
                       onWillPresent: onWillPresent,
                       onDismiss: onDismiss.map { cb in { _ in cb() } },
                       onFailedToPresent: onFailedToPresent)

        ad.paidEventHandler = { adValue in
            AdRevenueTracker.shared.trackAdRevenue(
                adValue: adValue,
                adUnit: adUnitId,
                adType: .openResume
            )
        }

        // 4) Present - GADAppOpenAd requires root view controller
        guard let rootVC = UIApplication.firstWindow?.rootViewController else {
            onEvent?(.failedToPresent(adUnitId: adUnitId, error: AdError.noViewControllerToPresent))
            return false
        }
        let presentingVC = rootVC.topmostPresentedViewController
        ad.fullScreenContentDelegate = self
        onEvent?(.willPresent(adUnitId: adUnitId))
        ad.present(from: presentingVC)

        return true
    }
}

// MARK: - PreloadDelegate (Preview header protocol)

extension AppOpenPreload: PreloadDelegate {

    public func adAvailable(forPreloadID preloadID: String, responseInfo: ResponseInfo) {
        onEvent?(.preloadAvailable(preloadID: preloadID, responseInfo: responseInfo))
    }

    public func adsExhausted(forPreloadID preloadID: String) {
        onEvent?(.preloadExhausted(preloadID: preloadID))

        let bufferSize = store.buffer(for: preloadID)
        if bufferSize == 0 {
            onEvent?(.preloadSkippedExhausted(preloadID: preloadID))
            return
        }
        guard config.autoPreloadOnExhausted else { return }
        preload(adUnitId: preloadID, bufferSize: bufferSize)
    }

    public func adFailedToPreload(forPreloadID preloadID: String, error: Error) {
        onEvent?(.preloadFailed(preloadID: preloadID, error: error))
    }
}

// MARK: - FullScreenContentDelegate

extension AppOpenPreload: FullScreenContentDelegate {

    public func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        guard let entry = store.peek(ObjectIdentifier(ad)) else { return }
        onEvent?(.willPresent(adUnitId: entry.adUnitId))
        entry.onWillPresent?()
    }

    public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        guard let entry = store.take(ObjectIdentifier(ad)) else { return }
        onEvent?(.didDismiss(adUnitId: entry.adUnitId))
        if store.buffer(for: entry.adUnitId) == 0 {
            AppOpenAdPreloader.shared.stopPreloadingAndRemoveAds(for: entry.adUnitId)
        }
        entry.onDismiss?(false)
    }

    public func ad(_ ad: FullScreenPresentingAd,
                   didFailToPresentFullScreenContentWithError error: Error) {
        guard let entry = store.take(ObjectIdentifier(ad)) else { return }
        onEvent?(.failedToPresent(adUnitId: entry.adUnitId, error: error))
        entry.onDismiss?(false)
        entry.onFailedToPresent?(error)
    }
}
