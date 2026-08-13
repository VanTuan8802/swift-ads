//
//  NativeAdColorConfig.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import GoogleMobileAds
import SwiftUI

public struct NativeAdColorConfig {
    public let headlineColor: Color
    public let bodyColor: Color
    public let adColor: Color
    public let adBackgroundColor: Color
    public let callToActionBackgroundColor: Color
    public let callToActionTextColor: Color
    public let backgroundColor: Color

    public init(
        headlineColor: Color = .black,
        bodyColor: Color = .gray,
        adColor: Color = .white,
        adBackgroundColor: Color = .blue,
        callToActionBackgroundColor: Color = .blue,
        callToActionTextColor: Color = .white,
        backgroundColor: Color = .black
    ) {
        self.headlineColor = headlineColor
        self.bodyColor = bodyColor
        self.adColor = adColor
        self.adBackgroundColor = adBackgroundColor
        self.callToActionBackgroundColor = callToActionBackgroundColor
        self.callToActionTextColor = callToActionTextColor
        self.backgroundColor = backgroundColor
    }

    public func copyWith(
        headlineColor: Color? = nil,
        bodyColor: Color? = nil,
        adColor: Color? = nil,
        adBackgroundColor: Color? = nil,
        advertiserBackgroundColor: Color? = nil,
        callToActionBackgroundColor: Color? = nil,
        callToActionTextColor: Color? = nil,
        backgroundColor: Color? = nil
    ) -> NativeAdColorConfig {
        return NativeAdColorConfig(
            headlineColor: headlineColor ?? self.headlineColor,
            bodyColor: bodyColor ?? self.bodyColor,
            adColor: adColor ?? self.adColor,
            adBackgroundColor: adBackgroundColor ?? self.adBackgroundColor,
            callToActionBackgroundColor: callToActionBackgroundColor ?? self.callToActionBackgroundColor,
            callToActionTextColor: callToActionTextColor ?? self.callToActionTextColor,
            backgroundColor: backgroundColor ?? self.backgroundColor
        )
    }
}

public enum NativeAdViewStyle: Equatable {
    case homeAd
    case homeAdNoMedia
    case nativeLargeMediaCtaBottom
    case nativeLargeMediaCtaTop
    case nativeNormalMediaCtaTop
    case nativeNormalMediaCtaBottom
    case small
    /// Custom layout loaded from a `.xib` you design in Interface Builder.
    /// The xib's root view must be a `NativeAdView` (GADNativeAdView) with the standard
    /// outlets connected (headlineView, bodyView, iconView, mediaView, callToActionView).
    /// Add a `UILabel` with tag 9 if you want the "Ad" badge styled by `NativeAdColorConfig`.
    /// Prefer the `custom(nibName:bundle:height:)` factory for default arguments.
    case customNib(nibName: String, bundle: Bundle, height: CGFloat)

    /// Convenience factory for a custom xib layout.
    /// Defaults to the app's main bundle (where your own xib lives) and 300pt height.
    public static func custom(
        nibName: String,
        bundle: Bundle = .main,
        height: CGFloat = 300
    ) -> NativeAdViewStyle {
        .customNib(nibName: nibName, bundle: bundle, height: height)
    }

    @MainActor var view: NativeAdView {
        switch self {
        case .nativeLargeMediaCtaBottom:
            return makeNibView(name: "LargeNativeCtaBottomAdView")
        case .nativeLargeMediaCtaTop:
            return makeNibView(name: "LargeNativeCtaTopAdView")
        case .nativeNormalMediaCtaBottom:
            return makeNibView(name: "NormalNativeCtaBottomAdView")
        case .nativeNormalMediaCtaTop:
            return makeNibView(name: "NormalNativeCtaTopAdView")
        case .homeAd:
            return makeNibView(name: "NormalNativeAdView")
        case .homeAdNoMedia:
            return makeNibView(name: "NormalNativeAdNoMediaView")
        case .small:
            return makeNibView(name: "SmallAdView")
        case let .customNib(nibName, bundle, _):
            return makeNibView(name: nibName, bundle: bundle)
        }
    }

    @MainActor func makeNibView(name: String, bundle: Bundle = .module) -> NativeAdView {
        let nib = UINib(nibName: name, bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! NativeAdView
    }

    var height: CGFloat {
        switch self {
        case .small:
            return 61
        case .homeAd:
            return 180
        case .homeAdNoMedia:
            return 130
        case .nativeNormalMediaCtaBottom, .nativeNormalMediaCtaTop:
            return 200
        case .nativeLargeMediaCtaBottom, .nativeLargeMediaCtaTop:
            return 300
        case let .customNib(_, _, height):
            return height
        }
    }
}
