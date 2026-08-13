//
//  RewardedInterPreload.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//
//  Rewarded Interstitial Ad Loader using Ad Preloading V2 (Preview headers)
//

import Foundation
import UIKit
import GoogleMobileAds
import PreloadPreview

/// Rewarded Interstitial Ad Loader using Ad Preloading V2 (Preview headers)
public final class RewardedInterPreload: NSObject, @unchecked Sendable {

    public static let shared = RewardedInterPreload()
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
        case didDismiss(adUnitId: String, wasRewarded: Bool)
        case failedToPresent(adUnitId: String, error: Error)
        case userEarnedReward(adUnitId: String)
    }

    public var onEvent: ((Event) -> Void)?

    // MARK: - Public API

    /// Start/refresh preloading for a rewarded interstitial ad unit ID.
    /// - Parameter bufferSize: Số lượng quảng cáo muốn giữ trong bộ đệm (mặc định 1). Nếu > 0 sẽ tự động preload.
    public func preload(adUnitId: String, bufferSize: Int = 1) {
        store.setBuffer(bufferSize, for: adUnitId)

        let request = Request()
        let cfg = PreloadConfigurationV2(adUnitID: adUnitId, request: request)
        cfg.bufferSize = UInt(bufferSize)

        onEvent?(.preloadStarted(adUnitId: adUnitId))

        RewardedInterstitialAdPreloader.shared.preload(
            for: adUnitId,
            configuration: cfg,
            delegate: self
        )
    }

    /// Verify that an ad is available before polling.
    public func isAvailable(adUnitId: String) -> Bool {
        return RewardedInterstitialAdPreloader.shared.isAdAvailable(with: adUnitId)
    }

    /// Poll and show the next available rewarded interstitial ad for the given adUnitId.
    @MainActor
    public func show(adUnitId: String,
                     onWillPresent: (() -> Void)? = nil,
                     onDismiss: ((Bool) -> Void)? = nil,
                     onFailedToPresent: ((Error) -> Void)? = nil,
                     onRewarded: (() -> Void)? = nil) -> Bool {

        guard isAvailable(adUnitId: adUnitId) else {
            onEvent?(.showNotAvailable(adUnitId: adUnitId))
            return false
        }

        guard let ad = RewardedInterstitialAdPreloader.shared.ad(with: adUnitId) else {
            onEvent?(.polledNil(adUnitId: adUnitId))
            return false
        }

        let oid = ObjectIdentifier(ad)
        store.register(oid,
                       adUnitId: adUnitId,
                       onWillPresent: onWillPresent,
                       onDismiss: onDismiss,
                       onFailedToPresent: onFailedToPresent,
                       onRewarded: onRewarded)

        ad.paidEventHandler = { adValue in
            AdRevenueTracker.shared.trackAdRevenue(
                adValue: adValue,
                adUnit: adUnitId,
                adType: .rewardedInterstitial
            )
        }

        ad.fullScreenContentDelegate = self
        onEvent?(.willPresent(adUnitId: adUnitId))
        ad.present(from: nil) { [weak self] in
            guard let self, let entry = self.store.markRewarded(oid) else { return }
            self.onEvent?(.userEarnedReward(adUnitId: entry.adUnitId))
            entry.onRewarded?()
        }

        return true
    }
}

// MARK: - PreloadDelegate

extension RewardedInterPreload: PreloadDelegate {
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

extension RewardedInterPreload: FullScreenContentDelegate {
    public func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        guard let entry = store.peek(ObjectIdentifier(ad)) else { return }
        onEvent?(.willPresent(adUnitId: entry.adUnitId))
        entry.onWillPresent?()
    }

    public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        guard let entry = store.take(ObjectIdentifier(ad)) else { return }
        onEvent?(.didDismiss(adUnitId: entry.adUnitId, wasRewarded: entry.wasRewarded))
        if store.buffer(for: entry.adUnitId) == 0 {
            RewardedInterstitialAdPreloader.shared.stopPreloadingAndRemoveAds(for: entry.adUnitId)
        }
        entry.onDismiss?(entry.wasRewarded)
    }

    public func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        guard let entry = store.take(ObjectIdentifier(ad)) else { return }
        onEvent?(.failedToPresent(adUnitId: entry.adUnitId, error: error))
        entry.onDismiss?(entry.wasRewarded)
        entry.onFailedToPresent?(error)
    }
}
