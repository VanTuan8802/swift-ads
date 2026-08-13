//
//  AdsAnalytics.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//
//  Fan-out ad revenue + purchase events tới Adjust / Firebase / Meta.
//  Port từ template AdMobModule (RevenueLogging + AdjustManager + FacebookManager),
//  generic hoá: token inject qua AdsAnalyticsConfig thay vì đọc Remote Config của app.
//

import Foundation
import AppTrackingTransparency
import GoogleMobileAds
import AdjustSdk
import FirebaseAnalytics
import FacebookCore

public final class AdsAnalytics: @unchecked Sendable {
    public static let shared = AdsAnalytics()

    private var config = AdsAnalyticsConfig()
    private var started = false

    /// True sau khi Meta SDK init thành công (FacebookAppID trong Info.plist là giá trị
    /// thật). Còn placeholder / thiếu key → false → các hàm log Meta no-op.
    public private(set) var isFacebookConfigured = false

    private init() {}

    // MARK: - Start

    /// Init Adjust + Meta và tự wire fan-out revenue từ AdRevenueTracker.
    /// Gọi 1 lần SAU khi user trả lời ATT prompt (thường ở Splash) — IDFA của Meta
    /// chỉ bật khi ATT authorized, tránh App Review reject 5.1.1(iv).
    /// FirebaseApp.configure() là việc của app, phải chạy trước khi event đầu tiên bắn.
    @MainActor
    public func start(config: AdsAnalyticsConfig) {
        self.config = config
        guard !started else { return }
        started = true

        initAdjust()
        initFacebook()

        AdRevenueTracker.shared.analyticsHandler = { [weak self] adValue, adUnit, adType in
            self?.handleAdRevenue(adValue: adValue, adUnit: adUnit, adType: adType)
        }
    }

    // MARK: - Adjust

    private func initAdjust() {
        guard !config.adjustAppToken.isEmpty else {
            log("Adjust app token rỗng — bỏ qua init Adjust")
            return
        }
#if DEBUG
        let adjustConfig = ADJConfig(appToken: config.adjustAppToken, environment: ADJEnvironmentSandbox)
        adjustConfig?.logLevel = .verbose
#else
        let adjustConfig = ADJConfig(appToken: config.adjustAppToken, environment: ADJEnvironmentProduction)
        adjustConfig?.logLevel = .suppress
#endif
        Adjust.initSdk(adjustConfig)
    }

    /// Track 1 event Adjust tuỳ ý. Param non-String được stringify (Adjust partner
    /// param chỉ nhận String).
    public func trackEvent(eventToken: String, parameters: [String: Any]? = nil) {
        let event = ADJEvent(eventToken: eventToken)
        parameters?.forEach { key, value in
            event?.addPartnerParameter(key, value: String(describing: value))
        }
        Adjust.trackEvent(event)
    }

    /// Track 1 giao dịch IAP one-time (gói lifetime) — fan-out Adjust (event `purchase`)
    /// + Meta (`fb_mobile_purchase`). Gói subscription dùng `trackSubscription`.
    public func trackPurchase(productId: String, transactionId: String, revenue: Double, currency: String) {
        logFacebookPurchase(amount: revenue, currency: currency)

        guard !config.adjustPurchaseEventToken.isEmpty else {
            log("purchase event token chưa cấu hình — bỏ qua Adjust event")
            return
        }
        let event = ADJEvent(eventToken: config.adjustPurchaseEventToken)
        event?.setRevenue(revenue, currency: currency)
        event?.addPartnerParameter("product_id", value: productId)
        event?.addPartnerParameter("transaction_id", value: transactionId)
        Adjust.trackEvent(event)
    }

    /// Track auto-renewing subscription qua API subscription chuyên dụng của Adjust —
    /// không cần event token; các kỳ renew sau Adjust tự nhận qua App Store Server
    /// Notifications (cấu hình ở dashboard).
    public func trackSubscription(productId: String, price: Decimal, currency: String,
                                  transactionId: String, transactionDate: Date, salesRegion: String?) {
        logFacebookPurchase(amount: NSDecimalNumber(decimal: price).doubleValue, currency: currency)

        guard let subscription = ADJAppStoreSubscription(
            price: NSDecimalNumber(decimal: price),
            currency: currency,
            transactionId: transactionId
        ) else { return }
        subscription.setTransactionDate(transactionDate)
        if let salesRegion {
            subscription.setSalesRegion(salesRegion)
        }
        subscription.addPartnerParameter("product_id", value: productId)
        Adjust.trackAppStoreSubscription(subscription)
    }

    // MARK: - Facebook / Meta

    /// Init Meta SDK — chỉ dùng FacebookCore (app events + install attribution).
    /// Self-skip nếu `FacebookAppID` trong Info.plist thiếu hoặc còn placeholder.
    /// Yêu cầu Info.plist tắt FacebookAutoInitEnabled + FacebookAutoLogAppEventsEnabled
    /// + FacebookAdvertiserIDCollectionEnabled để SDK không thu thập gì trước consent.
    @MainActor
    private func initFacebook() {
        let appID = Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String ?? ""
        guard !appID.isEmpty, !appID.contains("REPLACE"), !appID.contains("YOUR_") else {
            log("FacebookAppID thiếu hoặc còn placeholder — bỏ qua init Meta SDK")
            return
        }

        let attAuthorized = ATTrackingManager.trackingAuthorizationStatus == .authorized

        // IDFA + advertiser tracking CHỈ bật khi user cho phép ATT.
        Settings.shared.isAdvertiserIDCollectionEnabled = attAuthorized
        Settings.shared.isAdvertiserTrackingEnabled = attAuthorized
        // App events (không cần IDFA) bật vô điều kiện — giống Firebase Analytics.
        Settings.shared.isAutoLogAppEventsEnabled = true

        ApplicationDelegate.shared.initializeSDK()

        // Init trễ sau ATT → SDK đã lỡ hook activate tự động lúc launch, phải bắn
        // `fb_mobile_activate_app` thủ công, nếu không Events Manager trống.
        AppEvents.shared.activateApp()

        isFacebookConfigured = true
        log("Facebook SDK initialized (ATT authorized: \(attAuthorized))")
    }

    private func logFacebookPurchase(amount: Double, currency: String) {
        guard isFacebookConfigured else { return }
        AppEvents.shared.logPurchase(amount: amount, currency: currency)
    }

    private func logFacebookAdImpression(value: Double, currency: String, adType: String) {
        guard isFacebookConfigured else { return }
        AppEvents.shared.logEvent(
            .adImpression,
            valueToSum: value,
            parameters: [
                .currency: currency,
                .adType: adType,
            ]
        )
    }

    // MARK: - Revenue fan-out

    private func handleAdRevenue(adValue: AdValue, adUnit: String, adType: AdType) {
        let amount = Double(truncating: adValue.value)
        let currency = adValue.currencyCode
        log("AdRevenue \(adType.rawValue): \(amount) \(currency) | \(adUnit)")

        // 1) Firebase / GA4 — event doanh thu (khớp spec dashboard ROAS).
        logFirebaseRevenue(name: config.firebaseAdRevenueEventName, value: amount, currency: currency)

        // 2) Adjust — API đo lường ad-revenue chuyên dụng + event `ad_impression_custom`.
        trackAdjustAdRevenue(adValue: adValue, adType: adType.rawValue)

        // 3) Meta — standard event `AdImpression`.
        logFacebookAdImpression(value: amount, currency: currency, adType: adType.rawValue)
    }

    private func trackAdjustAdRevenue(adValue: AdValue, adType: String) {
        let revenue = Double(truncating: adValue.value)
        let currency = adValue.currencyCode

        let adjustAdRevenue = ADJAdRevenue(source: config.adjustAdRevenueSource)
        adjustAdRevenue?.setRevenue(revenue, currency: currency)
        adjustAdRevenue?.setAdImpressionsCount(1)
        adjustAdRevenue?.setAdRevenueNetwork("AdMob")
        adjustAdRevenue?.setAdRevenueUnit(adType)
        adjustAdRevenue?.setAdRevenuePlacement("default")
        if let adjustAdRevenue {
            Adjust.trackAdRevenue(adjustAdRevenue)
        }

        guard !config.adjustAdImpressionEventToken.isEmpty else {
            log("ad_impression_custom event token chưa cấu hình — bỏ qua")
            return
        }
        let event = ADJEvent(eventToken: config.adjustAdImpressionEventToken)
        event?.setRevenue(revenue, currency: currency)
        Adjust.trackEvent(event)
    }

    /// Log doanh thu lên Firebase/GA4. Currency lấy từ `adValue.currencyCode` thật
    /// (AdMob thường trả USD nhưng không đảm bảo).
    public func logFirebaseRevenue(name: String, value: Double, currency: String = "USD") {
        let safeRevenue = Double(String(format: "%.6f", value)) ?? 0.0
        Analytics.logEvent(name, parameters: [
            AnalyticsParameterAdPlatform: "AdMob",
            AnalyticsParameterCurrency: currency,
            AnalyticsParameterValue: safeRevenue,
        ])
    }

    private func log(_ message: String) {
#if DEBUG
        print("AdsAnalytics: \(message)")
#endif
    }
}
