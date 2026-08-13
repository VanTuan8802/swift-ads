//
//  NativeAdViewModel.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import SwiftUI
import GoogleMobileAds

public class NativeAdViewModel: NSObject, ObservableObject, NativeAdLoaderDelegate {
    @Published public var nativeAd: NativeAd?
    @Published public var isLoading: Bool = false
    @Published public var isLoadFailed: Bool = false
    private var adLoader: AdLoader!
    private var adUnitID: String

    /// - Parameter adUnitID: bắt buộc truyền tường minh — không có default để tránh
    ///   app quên truyền ID rồi âm thầm chạy test ad ngoài production.
    public init(adUnitID: String) {
        self.adUnitID = adUnitID
    }

    public func refreshAd() {
        guard !isLoading else {
            AdsLog.debug("NativeAd", "Previous request is still loading, new request is canceled.")
            return
        }
        isLoading = true
        isLoadFailed = false

        let adViewOptions = NativeAdViewAdOptions()
        adViewOptions.preferredAdChoicesPosition = .topRightCorner
        
        adLoader = AdLoader(adUnitID: adUnitID, rootViewController: nil, adTypes: [.native], options: [adViewOptions])
        adLoader.delegate = self
        adLoader.load(Request())
    }

    public func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        self.nativeAd = nativeAd
        nativeAd.delegate = self
        // Capture adUnitID theo value — paid event có thể đến sau khi
        // view model bị release, weak self sẽ làm mất tracking doanh thu.
        nativeAd.paidEventHandler = { [adUnitID] adValue in
            AdRevenueTracker.shared.trackAdRevenue(adValue: adValue,
                                                   adUnit: adUnitID,
                                                   adType: .native)
        }
        self.isLoading = false
        nativeAd.mediaContent.videoController.delegate = self
    }

    public func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        AdsLog.debug("NativeAd", "\(adLoader) failed with error: \(error.localizedDescription)")
        self.isLoading = false
        self.isLoadFailed = true
    }
}

extension NativeAdViewModel: VideoControllerDelegate {
    // GADVideoControllerDelegate methods
    public func videoControllerDidPlayVideo(_ videoController: VideoController) {
        // Implement this method to receive a notification when the video controller
        // begins playing the ad.
    }
    
    public func videoControllerDidPauseVideo(_ videoController: VideoController) {
        // Implement this method to receive a notification when the video controller
        // pauses the ad.
    }
    
    public func videoControllerDidEndVideoPlayback(_ videoController: VideoController) {
        // Implement this method to receive a notification when the video controller
        // stops playing the ad.
    }
    
    public func videoControllerDidMuteVideo(_ videoController: VideoController) {
        // Implement this method to receive a notification when the video controller
        // mutes the ad.
    }
    
    public func videoControllerDidUnmuteVideo(_ videoController: VideoController) {
        // Implement this method to receive a notification when the video controller
        // unmutes the ad.
    }
}

// MARK: - GADNativeAdDelegate implementation
extension NativeAdViewModel: NativeAdDelegate {
    public func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        AdsLog.debug("NativeAd", "\(#function) called")
    }

    public func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        AdsLog.debug("NativeAd", "\(#function) called")
    }

    public func nativeAdWillPresentScreen(_ nativeAd: NativeAd) {
        AdsLog.debug("NativeAd", "\(#function) called")
    }

    public func nativeAdWillDismissScreen(_ nativeAd: NativeAd) {
        AdsLog.debug("NativeAd", "\(#function) called")
    }

    public func nativeAdDidDismissScreen(_ nativeAd: NativeAd) {
        AdsLog.debug("NativeAd", "\(#function) called")
    }
}
