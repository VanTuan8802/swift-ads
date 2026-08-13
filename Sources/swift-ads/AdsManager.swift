//
//  AdsManager.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import SwiftUI
import GoogleMobileAds
import Network
import Combine

public enum AdType: String {
    case banner
    case native
    case nativeFullScreen
    case openResume
    case interstitial
    case rewarded
    case rewardedInterstitial
}

public class AdsManager: NSObject, @unchecked Sendable {
    
    public static let shared = AdsManager()
    
    public var isFullscreenAdShowing = false
    private var interLastTime: Date?
    private var interIntervalInSeconds: Int = 15
    var hasInternet = true
    private var initialized = false
    private var appOpenAdController: AppOpenAdModel?
    private var currentInterstitialController: InterstitialViewModel?
    private var currentRewardedController: RewardedViewModel?
    private var currentRewardedInterstitialController: RewardedInterstitialViewModel?
    var nativeAdColorConfig: NativeAdColorConfig = NativeAdColorConfig()
    public var animationFiles: [String]?
    
    public var appLifecycleReactor: AppLifecycleReactor?
    
    private override init() {
        super.init()
        startInternetMonitoring()
    }
    
    /// - Parameters:
    ///   - onAdRevenue: handler tuỳ ý của app, chạy song song với `analytics`.
    ///   - analytics: bật fan-out Adjust + Firebase + Meta có sẵn trong package.
    ///     Chỉ truyền khi initialize được gọi SAU ATT prompt (Meta cần trạng thái ATT);
    ///     nếu flow khác, gọi riêng `AdsAnalytics.shared.start(config:)` tại thời điểm đúng.
    @MainActor
    public func initialize(
        intervalShowInter: Int? = nil,
        nativeAdColorConfig: NativeAdColorConfig? = nil,
        animationFiles: [String]? = nil,
        onAdRevenue: AdRevenueHandler? = nil,
        analytics: AdsAnalyticsConfig? = nil
    ) {
        guard !initialized else { return }
        if let onAdRevenue {
            AdRevenueTracker.shared.onAdRevenue = onAdRevenue
        }
        if let analytics {
            AdsAnalytics.shared.start(config: analytics)
        }
        MobileAds.shared.start()
        if let customConfig = nativeAdColorConfig {
            self.nativeAdColorConfig = customConfig
        }
        if let customAnimationFiles = animationFiles {
            self.animationFiles = customAnimationFiles
        }
        interIntervalInSeconds = intervalShowInter ?? 15
        initialized = true
    }

    public func initAppOpenAd(
        appOpenAdUnitId: String,
        opacity: Int = 0,
        autoEnable: Bool = true
    ) {
        guard !appOpenAdUnitId.isEmpty else { return }
        appLifecycleReactor = AppLifecycleReactor()
        appLifecycleReactor?.setShouldShow(autoEnable)
        appLifecycleReactor?.setAppOpenAdId(appOpenAdUnitId)
        appLifecycleReactor?.listenToAppStateChanges()
        preloadAppOpenAd(adUnitID: appOpenAdUnitId, opacity: opacity)
    }

    public func preloadAppOpenAd(
        adUnitID: String,
        opacity: Int = 0
    ) {
        guard !adUnitID.isEmpty,
              opacity > 0,
              !AppOpenPreload.shared.isAvailable(adUnitId: adUnitID) else { return }
        AppOpenPreload.shared.preload(adUnitId: adUnitID, bufferSize: opacity)
    }
    
    public func preloadInterstitialAd(
        adUnitID: String,
        opacity: Int = 0
    ) {
        guard !adUnitID.isEmpty,
              opacity > 0,
              !InterPreload.shared.isAvailable(adUnitId: adUnitID) else { return }
        InterPreload.shared.preload(adUnitId: adUnitID, bufferSize: opacity)
    }

    public func preloadRewardedAd(
        adUnitID: String,
        opacity: Int = 0
    ) {
        guard !adUnitID.isEmpty,
              opacity > 0,
              !RewardsPreload.shared.isAvailable(adUnitId: adUnitID) else { return }
        RewardsPreload.shared.preload(adUnitId: adUnitID, bufferSize: opacity)
    }

    public func preloadRewardedInterstitialAd(
        adUnitID: String,
        opacity: Int = 0
    ) {
        guard !adUnitID.isEmpty,
              opacity > 0,
              !RewardedInterPreload.shared.isAvailable(adUnitId: adUnitID) else { return }
        RewardedInterPreload.shared.preload(adUnitId: adUnitID, bufferSize: opacity)
    }

    @MainActor
    public func showRewardedAd(
        adUnitID: String,
        onShowed: (() -> Void)? = nil,
        onDismissed: ((Bool) -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil,
        onRewarded: (() -> Void)? = nil,
        showLoading: Bool = true
    ) {
        guard !adUnitID.isEmpty else {
            onFailed?(AdError.emptyAdUnitID)
            return
        }

        do {
            try validateAdConditions(forceShow: true)
            
            // Luôn ưu tiên dùng preload nếu đã có sẵn trong kho
            if RewardsPreload.shared.isAvailable(adUnitId: adUnitID) {
                let success = RewardsPreload.shared.show(
                    adUnitId: adUnitID,
                    onWillPresent: { [weak self] in
                        self?.isFullscreenAdShowing = true
                        onShowed?()
                    },
                    onDismiss: { [weak self] wasRewarded in
                        self?.isFullscreenAdShowing = false
                        onDismissed?(wasRewarded)
                    },
                    onFailedToPresent: { [weak self] _ in
                        self?.isFullscreenAdShowing = false
                    },
                    onRewarded: {
                        onRewarded?()
                    }
                )
                if success { return }
            }
            
            currentRewardedController = RewardedViewModel(adUnitID: adUnitID,
                                                          showLoading: showLoading)
            setupRewardedCallbacks(
                onShowed: onShowed,
                onDismissed: onDismissed,
                onFailed: onFailed,
                onRewarded: onRewarded
            )
            
            currentRewardedController?.showAd()
        } catch {
            onFailed?(error)
        }
    }

    @MainActor
    public func showRewardedInterstitialAd(
        adUnitID: String,
        onShowed: (() -> Void)? = nil,
        onDismissed: ((Bool) -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil,
        onRewarded: (() -> Void)? = nil,
        showLoading: Bool = true
    ) {
        guard !adUnitID.isEmpty else {
            onFailed?(AdError.emptyAdUnitID)
            return
        }

        do {
            try validateAdConditions(forceShow: true)
            
            // Luôn ưu tiên dùng preload nếu đã có sẵn trong kho
            if RewardedInterPreload.shared.isAvailable(adUnitId: adUnitID) {
                let success = RewardedInterPreload.shared.show(
                    adUnitId: adUnitID,
                    onWillPresent: { [weak self] in
                        self?.isFullscreenAdShowing = true
                        onShowed?()
                    },
                    onDismiss: { [weak self] wasRewarded in
                        self?.isFullscreenAdShowing = false
                        onDismissed?(wasRewarded)
                    },
                    onFailedToPresent: { [weak self] _ in
                        self?.isFullscreenAdShowing = false
                    },
                    onRewarded: {
                        onRewarded?()
                    }
                )
                if success { return }
            }
            
            currentRewardedInterstitialController = RewardedInterstitialViewModel(adUnitID: adUnitID,
                                                                                  showLoading: showLoading)
            setupRewardedInterstitialCallbacks(
                onShowed: onShowed,
                onDismissed: onDismissed,
                onFailed: onFailed,
                onRewarded: onRewarded
            )
            
            currentRewardedInterstitialController?.showAd()
        } catch {
            onFailed?(error)
        }
    }
    
    @MainActor
    public func showInterstitialAd(
        adUnitID: String,
        onShowed: (() -> Void)? = nil,
        onDismissed: (() -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil,
        forceShow: Bool = false,
        showLoading: Bool = true
    ) {
        guard !adUnitID.isEmpty else {
            onFailed?(AdError.emptyAdUnitID)
            return
        }

        do {
            try validateAdConditions(adUnitID: adUnitID, forceShow: forceShow)
            
            // Luôn ưu tiên dùng preload nếu đã có sẵn trong kho
            if InterPreload.shared.isAvailable(adUnitId: adUnitID) {
                let success = InterPreload.shared.show(
                    adUnitId: adUnitID,
                    onWillPresent: { [weak self] in
                        self?.isFullscreenAdShowing = true
                        onShowed?()
                    },
                    onDismiss: { [weak self] in
                        self?.isFullscreenAdShowing = false
                        if !forceShow {
                            self?.updateLastShowTime()
                        }
                        onDismissed?()
                    },
                    onFailedToPresent: { [weak self] _ in
                        self?.isFullscreenAdShowing = false
                    }
                )
                if success { return }
            }
            
            currentInterstitialController = InterstitialViewModel(adUnitID: adUnitID,
                                                                  showLoading: showLoading)
            setupInterstitialCallbacks(
                onShowed: onShowed,
                onDismissed: onDismissed,
                onFailed: onFailed,
                forceShow: forceShow
            )
            
            currentInterstitialController?.showAd()
        } catch {
            onFailed?(error)
        }
    }
    
    @MainActor
    public func showAppOpenAd(
        adUnitID: String,
        onShowed: (() -> Void)? = nil,
        onDismissed: (() -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil,
        showLoading: Bool = true
    ) {
        guard !adUnitID.isEmpty else {
            onFailed?(AdError.emptyAdUnitID)
            return
        }

        do {
            try validateAdConditions(forceShow: true)

            // Luôn ưu tiên dùng preload nếu đã có sẵn trong kho
            if AppOpenPreload.shared.isAvailable(adUnitId: adUnitID) {
                let success = AppOpenPreload.shared.show(
                    adUnitId: adUnitID,
                    onWillPresent: { [weak self] in
                        self?.isFullscreenAdShowing = true
                        onShowed?()
                    },
                    onDismiss: { [weak self] in
                        self?.isFullscreenAdShowing = false
                        onDismissed?()
                    },
                    onFailedToPresent: { [weak self] _ in
                        self?.isFullscreenAdShowing = false
                    }
                )
                if success { return }
            }
            
            appOpenAdController = AppOpenAdModel(adUnitID: adUnitID, showLoading: showLoading)
            
            appOpenAdController?.onShowed = { [weak self] in
                self?.isFullscreenAdShowing = true
                onShowed?()
            }
            
            appOpenAdController?.onDismissed = { [weak self] in
                self?.isFullscreenAdShowing = false
                onDismissed?()
            }
            
            appOpenAdController?.onFailed = { [weak self] error in
                self?.isFullscreenAdShowing = false
                onFailed?(error)
            }
            
            appOpenAdController?.showAd()
        } catch {
            onFailed?(error)
        }
    }

    // MARK: - Native Full Screen (Popup)

    private var currentNativeFullScreenController: NativeFullScreenAdViewModel?

    /// Show a native ad as a full-screen popup (presented modally).
    /// Uses NativeFullScreenContentView internally.
    /// The popup will always show a close (x) button which automatically dismisses it.
    /// All colors from getNativeAdColorConfig().
    @MainActor
    public func showNativeFullScreenAd(
        adUnitID: String,
        onShowed: (() -> Void)? = nil,
        onDismissed: (() -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil,
        onCloseButtonTapped: (() -> Void)? = nil,
        showLoading: Bool = true
    ) {
        guard !adUnitID.isEmpty else {
            onFailed?(AdError.emptyAdUnitID)
            return
        }

        do {
            try validateAdConditions(forceShow: true)
        } catch {
            onFailed?(error)
            return
        }

        let controller = NativeFullScreenAdViewModel(
            adUnitID: adUnitID,
            showCloseButton: true // Popup always has a close button
        )
        currentNativeFullScreenController = controller

        controller.onShowed = { [weak self] in
            self?.isFullscreenAdShowing = true
            onShowed?()
        }

        controller.onDismissed = { [weak self] in
            self?.isFullscreenAdShowing = false
            self?.currentNativeFullScreenController = nil
            onDismissed?()
        }

        controller.onFailed = { [weak self] error in
            self?.isFullscreenAdShowing = false
            self?.currentNativeFullScreenController = nil
            onFailed?(error)
        }

        controller.onCloseButtonTapped = {
            onCloseButtonTapped?()
        }

        controller.showAd()
    }
    
    @MainActor
    private func validateAdConditions(adUnitID: String? = nil, forceShow: Bool = false) throws {
        guard hasInternet else {
            throw AdError.noInternet
        }
        
        guard !isFullscreenAdShowing else {
            throw AdError.adAlreadyShowing
        }
        
        if adUnitID != nil {
             guard forceShow || checkShowInter() else {
                 throw AdError.intervalNotMet
             }
        }
    }
    
    @MainActor
    private func setupRewardedCallbacks(
        onShowed: (() -> Void)?,
        onDismissed: ((Bool) -> Void)?,
        onFailed: ((Error) -> Void)?,
        onRewarded: (() -> Void)?
    ) {
        currentRewardedController?.onShowed = { [weak self] in
            self?.isFullscreenAdShowing = true
            onShowed?()
        }
        
        currentRewardedController?.onDismissed = { [weak self] wasRewarded in
            self?.isFullscreenAdShowing = false
            self?.currentRewardedController = nil
            onDismissed?(wasRewarded)
        }
        
        currentRewardedController?.onFailed = { [weak self] error in
            self?.isFullscreenAdShowing = false
            self?.currentRewardedController = nil
            onFailed?(error)
        }
        currentRewardedController?.onRewarded = {
            onRewarded?()
        }
    }
    
    @MainActor
    private func setupRewardedInterstitialCallbacks(
        onShowed: (() -> Void)?,
        onDismissed: ((Bool) -> Void)?,
        onFailed: ((Error) -> Void)?,
        onRewarded: (() -> Void)?
    ) {
        currentRewardedInterstitialController?.onShowed = { [weak self] in
            self?.isFullscreenAdShowing = true
            onShowed?()
        }
        
        currentRewardedInterstitialController?.onDismissed = { [weak self] wasRewarded in
            self?.isFullscreenAdShowing = false
            self?.currentRewardedInterstitialController = nil
            onDismissed?(wasRewarded)
        }
        
        currentRewardedInterstitialController?.onFailed = { [weak self] error in
            self?.isFullscreenAdShowing = false
            self?.currentRewardedInterstitialController = nil
            onFailed?(error)
        }
        currentRewardedInterstitialController?.onRewarded = {
            onRewarded?()
        }
    }
    
    @MainActor
    private func setupInterstitialCallbacks(
        onShowed: (() -> Void)?,
        onDismissed: (() -> Void)?,
        onFailed: ((Error) -> Void)?,
        forceShow: Bool
    ) {
        currentInterstitialController?.onShowed = { [weak self] in
            self?.isFullscreenAdShowing = true
            onShowed?()
        }
        
        currentInterstitialController?.onDismissed = { [weak self] in
            self?.isFullscreenAdShowing = false
            if !forceShow {
                self?.updateLastShowTime()
            }
            self?.currentInterstitialController = nil
            onDismissed?()
        }
        
        currentInterstitialController?.onFailed = { [weak self] error in
            self?.log("Interstitial ad failed: \(error.localizedDescription)")
            self?.isFullscreenAdShowing = false
            self?.currentInterstitialController = nil
            onFailed?(error)
        }
    }
    
    @MainActor
    private func checkShowInter() -> Bool {
        guard let lastTime = interLastTime else { return true }
        let currentTime = Date()
        let timeSinceLastAd = currentTime.timeIntervalSince(lastTime)
        return timeSinceLastAd >= TimeInterval(interIntervalInSeconds)
    }

    @MainActor
    private func updateLastShowTime() {
        interLastTime = Date()
    }
    
    private func startInternetMonitoring() {
        let monitor = NWPathMonitor()
        let internetUpdater = InternetStatusUpdater()
        monitor.pathUpdateHandler = { [internetUpdater] path in
            Task {
                await internetUpdater.updateStatus(path.status == .satisfied)
                await internetUpdater.notifyAdsManager()
            }
        }
        monitor.start(queue: DispatchQueue.global())
    }
    
    private func log(_ message: String) {
#if DEBUG
        print("AdManager: \(message)")
#endif
    }
    
    public func getNativeAdColorConfig() -> NativeAdColorConfig {
        return nativeAdColorConfig
    }
    
    public func setAnimationFiles(_ files: [String]?) {
        self.animationFiles = files
    }
}

// MARK: - AdError
public enum AdError: LocalizedError {
    case noInternet
    case adAlreadyShowing
    case intervalNotMet
    case emptyAdUnitID
    case noViewControllerToPresent

    public var errorDescription: String? {
        switch self {
        case .noInternet:
            return "No internet connection"
        case .adAlreadyShowing:
            return "Another ad is already showing"
        case .intervalNotMet:
            return "Interstitial ad interval not met"
        case .emptyAdUnitID:
            return "Ad unit ID is empty"
        case .noViewControllerToPresent:
            return "No view controller available to present the ad"
        }
    }
}

public class AppLifecycleReactor {
    private var shouldShow = false
    private var isExcludeScreen = false
    private var appOpenAdId: String?
    
    func listenToAppStateChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppStateChange),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    public func setShouldShow(_ value: Bool) {
        shouldShow = value
    }
    
    /// Nếu set = true khi ẩn app và vào lại sẽ không hiển thị app open ad.
    /// Vào lại app sẽ tự set lại = false
    public func setIsExcludeScreen(_ value: Bool) {
        isExcludeScreen = value
    }
    
    public func setAppOpenAdId(_ id: String?) {
        appOpenAdId = id
    }

    @MainActor
    @objc private func handleAppStateChange() {
        guard let appOpenAdId = appOpenAdId else {
            return
        }

        if AdsManager.shared.isFullscreenAdShowing || !shouldShow {
            return
        }

        if (isExcludeScreen) {
            isExcludeScreen = false
            return
        }
        AdsManager.shared.showAppOpenAd(adUnitID: appOpenAdId)
    }

}

actor InternetStatusUpdater {
    private var hasInternet = true
    
    func updateStatus(_ status: Bool) {
        hasInternet = status
    }
    
    func getStatus() -> Bool {
        return hasInternet
    }
    
    func notifyAdsManager() async {
        let status = getStatus()
        await MainActor.run {
            AdsManager.shared.hasInternet = status
        }
    }
}
