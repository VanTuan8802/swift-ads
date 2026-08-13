//
//  LargeNativeAdView.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import GoogleMobileAds
import SwiftUI

struct AdNativeView: UIViewRepresentable {
    typealias UIViewType = NativeAdView

    @ObservedObject var nativeViewModel: NativeAdViewModel
    var style: NativeAdViewStyle
    var colorConfig: NativeAdColorConfig?
    /// When set, the developer builds the `NativeAdView` themselves (full custom layout in
    /// code). The library still binds the ad data, AdChoices and root view controller, but does
    /// NOT apply `NativeAdColorConfig` — the builder owns all styling.
    var viewProvider: (@MainActor () -> NativeAdView)?

    init(nativeViewModel: NativeAdViewModel,
                style: NativeAdViewStyle = .nativeLargeMediaCtaBottom,
                colorConfig: NativeAdColorConfig? = nil,
                viewProvider: (@MainActor () -> NativeAdView)? = nil) {
        self.nativeViewModel = nativeViewModel
        self.style = style
        self.colorConfig = colorConfig
        self.viewProvider = viewProvider
    }

    func makeUIView(context: Context) -> NativeAdView {
        guard let viewProvider else { return style.view }
        let adView = viewProvider()
        // For custom code-built layouts, guarantee an AdChoices overlay (required ad
        // attribution) unless the developer already provided one.
        if adView.adChoicesView == nil {
            let adChoices = AdChoicesView()
            adChoices.translatesAutoresizingMaskIntoConstraints = false
            adView.addSubview(adChoices)
            NSLayoutConstraint.activate([
                adChoices.topAnchor.constraint(equalTo: adView.topAnchor, constant: 4),
                adChoices.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -4),
            ])
            adView.adChoicesView = adChoices
        }
        return adView
    }

    func removeCurrentSizeConstraints(from mediaView: UIView) {
        mediaView.constraints.forEach { constraint in
            if constraint.firstAttribute == .width || constraint.firstAttribute == .height {
                mediaView.removeConstraint(constraint)
            }
        }
    }

    func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        guard let nativeAd = nativeViewModel.nativeAd else { return }

        // Mấu chốt: Tránh re-assign trùng ad khi SwiftUI update layout, gây huỷ ngang trình mở AdMob
        if nativeAdView.nativeAd !== nativeAd {
            // Set text content
            (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
            nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
            (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
            (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
            (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
            nativeAdView.callToActionView?.isUserInteractionEnabled = false
            
            nativeAdView.nativeAd = nativeAd
        }

        // Apply color configuration only for built-in styles / xib layouts. A custom code
        // builder (viewProvider) owns its own styling, so we leave it untouched.
        if viewProvider == nil {
            let colorConfig = self.colorConfig ?? AdsManager.shared.getNativeAdColorConfig()
            if let adLabel = nativeAdView.viewWithTag(9) as? UILabel {
                adLabel.textColor = UIColor(colorConfig.adColor)
                adLabel.backgroundColor = UIColor(colorConfig.adBackgroundColor)
                adLabel.layer.cornerRadius = 8.0
                adLabel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMaxYCorner]
                adLabel.clipsToBounds = true
                adLabel.layer.masksToBounds = true
            }
            (nativeAdView.headlineView as? UILabel)?.textColor = UIColor(colorConfig.headlineColor)
            (nativeAdView.bodyView as? UILabel)?.textColor = UIColor(colorConfig.bodyColor)
            if let callToActionButton = nativeAdView.callToActionView as? UIButton {
                callToActionButton.backgroundColor = UIColor(colorConfig.callToActionBackgroundColor)
                callToActionButton.setTitleColor(UIColor(colorConfig.callToActionTextColor), for: .normal)
            }
        }

        // Find topmost view controller for presentation
        func getTopVC(_ base: UIViewController?) -> UIViewController? {
            if let nav = base as? UINavigationController {
                return getTopVC(nav.visibleViewController)
            } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
                return getTopVC(selected)
            } else if let presented = base?.presentedViewController {
                return getTopVC(presented)
            }
            return base
        }

        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let rootVC = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController {
            nativeAd.rootViewController = getTopVC(rootVC) ?? rootVC
        } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController {
            nativeAd.rootViewController = getTopVC(rootVC) ?? rootVC
        }
    }
}

struct NativeAdView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NativeAdViewModel(adUnitID: "ca-app-pub-3940256099942544/3986624511") // Google test ID (preview only)

        // Tạo colorConfig trực tiếp thay vì dùng AdsManager.shared để tránh crash trong preview
        let customColorConfig = NativeAdColorConfig(
            headlineColor: .red,
            bodyColor: .gray,
            adColor: .white,
            adBackgroundColor: .blue,
            callToActionBackgroundColor: .green,
            callToActionTextColor: .white
        )

        ScrollView {
            VStack {
                AdNativeView(nativeViewModel: viewModel, style: .nativeLargeMediaCtaBottom)
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .background(Color.red)
                
                AdNativeView(nativeViewModel: viewModel, style: .nativeLargeMediaCtaBottom,
                             colorConfig: customColorConfig)
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .background(Color.blue)
            }
            .padding()
        }
        .background(Color.gray)
    }
}
