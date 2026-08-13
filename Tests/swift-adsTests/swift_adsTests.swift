//
//  swift_adsTests.swift
//  swift-ads
//
//  Created by VanTuan8802 on 13/8/26.
//

import Testing
import Foundation
@testable import swift_ads

// MARK: - AdError

@Test func adErrorProvidesLocalizedDescription() {
    let errors: [AdError] = [.noInternet, .adAlreadyShowing, .intervalNotMet,
                             .emptyAdUnitID, .noViewControllerToPresent]
    for error in errors {
        #expect(error.errorDescription?.isEmpty == false)
        // LocalizedError phải nối vào localizedDescription chuẩn của Error
        #expect((error as Error).localizedDescription == error.errorDescription)
    }
}

// MARK: - AdsAnalyticsConfig

@Test func adsAnalyticsConfigDefaults() {
    let config = AdsAnalyticsConfig()
    #expect(config.adjustAppToken.isEmpty)
    #expect(config.adjustAdImpressionEventToken.isEmpty)
    #expect(config.adjustPurchaseEventToken.isEmpty)
    #expect(config.firebaseAdRevenueEventName == "ad_revenue")
    #expect(config.adjustAdRevenueSource == "admob_sdk")
}

// MARK: - AdType

@Test func adTypeRawValuesAreStable() {
    // Raw value được dùng làm ad_format trong analytics event — đổi là vỡ dashboard
    #expect(AdType.banner.rawValue == "banner")
    #expect(AdType.native.rawValue == "native")
    #expect(AdType.nativeFullScreen.rawValue == "nativeFullScreen")
    #expect(AdType.openResume.rawValue == "openResume")
    #expect(AdType.interstitial.rawValue == "interstitial")
    #expect(AdType.rewarded.rawValue == "rewarded")
    #expect(AdType.rewardedInterstitial.rawValue == "rewardedInterstitial")
}

// MARK: - PreloadCallbackStore

private final class DummyAd {}

@Test func preloadStoreRegisterPeekTake() {
    let store = PreloadCallbackStore()
    let ad = DummyAd()
    let oid = ObjectIdentifier(ad)

    var willPresentCount = 0
    store.register(oid, adUnitId: "unit-1", onWillPresent: { willPresentCount += 1 })

    #expect(store.adUnitId(for: oid) == "unit-1")
    store.peek(oid)?.onWillPresent?()
    #expect(willPresentCount == 1)

    // take xoá entry — lần hai phải nil (dismiss chỉ bắn 1 lần)
    #expect(store.take(oid) != nil)
    #expect(store.take(oid) == nil)
    #expect(store.adUnitId(for: oid) == nil)
}

@Test func preloadStoreMarkRewardedFlowsIntoDismiss() {
    let store = PreloadCallbackStore()
    let ad = DummyAd()
    let oid = ObjectIdentifier(ad)

    var rewardedCount = 0
    var dismissedWasRewarded: Bool?
    store.register(oid, adUnitId: "unit-1",
                   onDismiss: { dismissedWasRewarded = $0 },
                   onRewarded: { rewardedCount += 1 })

    let entry = store.markRewarded(oid)
    #expect(entry?.wasRewarded == true)
    entry?.onRewarded?()
    #expect(rewardedCount == 1)

    let taken = store.take(oid)
    taken?.onDismiss?(taken?.wasRewarded ?? false)
    #expect(dismissedWasRewarded == true)
}

@Test func preloadStoreBufferSizePerAdUnit() {
    let store = PreloadCallbackStore()
    #expect(store.buffer(for: "unknown") == 0)
    store.setBuffer(3, for: "unit-1")
    store.setBuffer(0, for: "unit-2")
    #expect(store.buffer(for: "unit-1") == 3)
    #expect(store.buffer(for: "unit-2") == 0)
}

@Test func preloadStoreSeparateEntriesPerAd() {
    let store = PreloadCallbackStore()
    let adA = DummyAd(), adB = DummyAd()
    store.register(ObjectIdentifier(adA), adUnitId: "unit-A")
    store.register(ObjectIdentifier(adB), adUnitId: "unit-B")

    #expect(store.take(ObjectIdentifier(adA))?.adUnitId == "unit-A")
    // Xoá A không ảnh hưởng B
    #expect(store.adUnitId(for: ObjectIdentifier(adB)) == "unit-B")
}

// MARK: - AdRevenueTracker fan-out

@Test @MainActor func revenueTrackerKeepsIndependentHandlers() {
    // Không tạo được AdValue (init internal của GMA) nên chỉ verify wiring:
    // analyticsHandler và onAdRevenue là 2 slot độc lập, gán cái này không đè cái kia.
    let tracker = AdRevenueTracker.shared
    defer {
        tracker.onAdRevenue = nil
        tracker.analyticsHandler = nil
    }

    tracker.onAdRevenue = { _, _, _ in }
    tracker.analyticsHandler = { _, _, _ in }
    #expect(tracker.onAdRevenue != nil)
    #expect(tracker.analyticsHandler != nil)

    tracker.onAdRevenue = nil
    #expect(tracker.analyticsHandler != nil)
}
