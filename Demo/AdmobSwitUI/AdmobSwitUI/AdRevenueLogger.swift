//
//  AdRevenueLogger.swift
//  AdmobSwitUI
//
//  Created by VanTuan8802 on 13/8/26.
//

import Foundation
import swift_ads
import GoogleMobileAds

class AdRevenueLogger: AdRevenueDelegate, @unchecked Sendable {
    static let shared = AdRevenueLogger()

    private init() {
        AdRevenueTracker.shared.delegate = self
    }

    func didTrackAdRevenue(adValue: AdValue, adUnit: String, adType: AdType) {
        print("💰 Ad Revenue: \(adValue.value) \(adValue.currencyCode) | Unit: \(adUnit) | Type: \(adType.rawValue)")
    }
}
