//
//  AdsAnalyticsConfig.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import Foundation

/// Token / tuỳ chọn cho bộ analytics fan-out (Adjust + Firebase + Meta).
/// App inject token (thường lấy từ Remote Config) — package không tự đọc config từ đâu cả.
/// Token rỗng → phần tương ứng self-skip, không crash.
public struct AdsAnalyticsConfig: Sendable {
    /// Adjust App Token — App Settings trên Adjust Dashboard. Rỗng → bỏ qua init Adjust.
    public var adjustAppToken: String
    /// Adjust event token cho `ad_impression_custom` — bắn mỗi ad impression có doanh thu.
    public var adjustAdImpressionEventToken: String
    /// Adjust event token cho `purchase` (one-time IAP). Rỗng → `trackPurchase` self-skip phần Adjust.
    public var adjustPurchaseEventToken: String
    /// Tên event doanh thu bắn lên Firebase/GA4 mỗi ad impression.
    public var firebaseAdRevenueEventName: String
    /// `source` truyền vào `ADJAdRevenue`.
    public var adjustAdRevenueSource: String

    public init(
        adjustAppToken: String = "",
        adjustAdImpressionEventToken: String = "",
        adjustPurchaseEventToken: String = "",
        firebaseAdRevenueEventName: String = "ad_revenue",
        adjustAdRevenueSource: String = "admob_sdk"
    ) {
        self.adjustAppToken = adjustAppToken
        self.adjustAdImpressionEventToken = adjustAdImpressionEventToken
        self.adjustPurchaseEventToken = adjustPurchaseEventToken
        self.firebaseAdRevenueEventName = firebaseAdRevenueEventName
        self.adjustAdRevenueSource = adjustAdRevenueSource
    }
}
