//
//  AdRevenueTracker.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import Foundation
import GoogleMobileAds

public typealias AdRevenueHandler = @Sendable (_ adValue: AdValue, _ adUnit: String, _ adType: AdType) -> Void

public protocol AdRevenueDelegate: AnyObject, Sendable {
    func didTrackAdRevenue(adValue: AdValue, adUnit: String, adType: AdType)
}

public class AdRevenueTracker: @unchecked Sendable {
    public static let shared = AdRevenueTracker()
    public weak var delegate: AdRevenueDelegate?
    public var onAdRevenue: AdRevenueHandler?
    /// Hook nội bộ cho AdsAnalytics (Adjust/Firebase/Meta fan-out) — tách khỏi
    /// `onAdRevenue` để app vẫn gắn thêm handler riêng mà không đè lên nhau.
    var analyticsHandler: AdRevenueHandler?

    private init() {}

    public func trackAdRevenue(adValue: AdValue, adUnit: String, adType: AdType) {
        analyticsHandler?(adValue, adUnit, adType)
        onAdRevenue?(adValue, adUnit, adType)
        delegate?.didTrackAdRevenue(adValue: adValue, adUnit: adUnit, adType: adType)
    }
}
