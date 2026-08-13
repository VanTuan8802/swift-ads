//
//  RewardedInterstitialViewModel.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import SwiftUI
import GoogleMobileAds

class RewardedInterstitialViewModel: NSObject {
    enum AdState {
        case idle
        case loading
        case ready
        case showing
    }
    
    private let adUnitID: String
    private var rewardedAd: RewardedInterstitialAd?
    private var loadingVC: AdLoadingVC?
    
    private(set) var state: AdState = .idle
    private var wasRewarded: Bool = false
    private var showLoading = true

    var onShowed: (() -> Void)?
    var onDismissed: ((Bool) -> Void)?
    var onFailed: ((Error) -> Void)?
    var onRewarded: (() -> Void)?
    var onPaid: ((AdValue) -> Void)?
    
    init(adUnitID: String, showLoading: Bool = true) {
        self.adUnitID = adUnitID
        self.showLoading = showLoading
        super.init()
    }

    @MainActor
    func showAd() {
        switch state {
        case .showing:
            return
        case .ready:
            presentAd()
        case .idle, .loading:
            loadAndShowAd()
        }
    }
    
    @MainActor
    private func loadAndShowAd() {
        guard state != .loading else { return }

        state = .loading
        showLoadingView()

        Task {
            do {
                let ad = try await RewardedInterstitialAd.load(
                    with: adUnitID,
                    request: Request()
                )

                self.rewardedAd = ad

                // Capture adUnitID theo value — paid event có thể đến sau khi
                // view model bị release, weak self sẽ làm mất tracking doanh thu.
                ad.paidEventHandler = { [adUnitID] adValue in
                    AdRevenueTracker.shared.trackAdRevenue(
                        adValue: adValue,
                        adUnit: adUnitID,
                        adType: .rewardedInterstitial
                    )
                }

                ad.fullScreenContentDelegate = self
                self.state = .ready

                dismissLoadingView {
                    self.presentAd()
                }

            } catch {
                print("RewardedInterstitialAd failed to load: \(error.localizedDescription)")
                self.state = .idle
                dismissLoadingView()
                self.onFailed?(error)
            }
        }
    }
    
    @MainActor
    private func presentAd() {
        guard let ad = rewardedAd else {
            return
        }
        
        state = .showing
        ad.present(from: nil) { [weak self] in
            self?.wasRewarded = true
            self?.onRewarded?()
        }
    }
    
    @MainActor
    private func showLoadingView() {
        if !showLoading {
            return
        }
        guard let topVC = UIApplication.getTopViewController() else {
            return
        }
        
        guard self.loadingVC == nil else {
            return
        }
        
        guard !(topVC is AdLoadingVC) else {
            return
        }
        
        let loadingVC = AdLoadingVC()
        
        loadingVC.blockDidDismiss = { [weak self] in
            self?.loadingVC = nil
        }
        
        self.loadingVC = loadingVC
        topVC.present(loadingVC, animated: false)
    }
    
    @MainActor
    private func dismissLoadingView(completion: (() -> Void)? = nil) {
        if !showLoading {
            completion?()
            return
        }
        guard let loadingVC = self.loadingVC else {
            completion?()
            return
        }
        
        loadingVC.blockDidDismiss = { [weak self] in
            self?.loadingVC = nil
            completion?()
        }
        loadingVC.dismissLoading()
    }
    
    private func log(_ message: String) {
#if DEBUG
        print("Rewarded: \(message)")
#endif
    }
}

// MARK: - FullScreenContentDelegate
extension RewardedInterstitialViewModel: FullScreenContentDelegate {
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        log("Ad impression recorded")
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        log("Ad click recorded")
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        log("Failed to present with error: \(error.localizedDescription)")
        state = .idle
        rewardedAd = nil
        onFailed?(error)
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        log("Will present full screen content")
        onShowed?()
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        log("Did dismiss full screen content")
        let rewarded = wasRewarded
        // Ad GMA chỉ present được 1 lần — reset để instance có thể load lại nếu tái dùng
        state = .idle
        rewardedAd = nil
        wasRewarded = false
        onDismissed?(rewarded)
    }
}
