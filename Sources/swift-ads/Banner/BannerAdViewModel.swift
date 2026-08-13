//
//  BannerAdViewModel.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import SwiftUI
import GoogleMobileAds

public class BannerAdViewModel: NSObject, ObservableObject, BannerViewDelegate {
    @Published public var adLoaded = false
    @Published public var isLoading = true

    public override init() {
        super.init()
    }

    // MARK: - BannerViewDelegate

    public func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        DispatchQueue.main.async {
            self.adLoaded = true
            self.isLoading = false
        }
    }

    public func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        DispatchQueue.main.async {
            self.adLoaded = false
            self.isLoading = false
        }
    }
}
