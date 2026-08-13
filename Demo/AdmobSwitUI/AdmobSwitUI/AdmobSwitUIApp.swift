//
//  AdmobSwitUIApp.swift
//  AdmobSwitUI
//
//  Created by VanTuan8802 on 13/8/26.
//

import SwiftUI
import swift_ads

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

}

@main
struct AdmobSwitUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView().task {
                // Khởi tạo AdsManager (kèm luôn revenue tracking, không cần logger riêng)
                AdsManager.shared.initialize(intervalShowInter: 15,
                                             animationFiles: ["loadingAds1", "loadingAds2"],
                                             onAdRevenue: { adValue, adUnit, adType in
                    print("💰 Ad Revenue: \(adValue.value) \(adValue.currencyCode) | Unit: \(adUnit) | Type: \(adType.rawValue)")
                })

                // Preload sớm các loại ad
                AdsManager.shared.preloadInterstitialAd(adUnitID: AdUnitID.interstitial, opacity: 1)
                AdsManager.shared.initAppOpenAd(appOpenAdUnitId: AdUnitID.appOpen, opacity: 1)
                AdsManager.shared.preloadRewardedAd(adUnitID: AdUnitID.rewarded, opacity: 1)
                AdsManager.shared.preloadRewardedInterstitialAd(adUnitID: AdUnitID.rewardedInterstitial, opacity: 1)

//                // Custom appOpen logic cũ (nếu vẫn cần)
//                CustomAppOpenAdManager.shared.initialize()
            }
        }
    }
}
