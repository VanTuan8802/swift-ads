//
//  NativeContentView.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import SwiftUI
import GoogleMobileAds

public struct NativeContentView: View {
    @ObservedObject var nativeViewModel: NativeAdViewModel
    var style: NativeAdViewStyle
    var colorConfig: NativeAdColorConfig?
    var height: CGFloat?
    var viewProvider: (@MainActor () -> NativeAdView)?

    public init(
        nativeViewModel: NativeAdViewModel,
        style: NativeAdViewStyle = .nativeLargeMediaCtaBottom,
        colorConfig: NativeAdColorConfig? = nil,
        height: CGFloat? = nil
    ) {
        self.nativeViewModel = nativeViewModel
        self.style = style
        self.colorConfig = colorConfig
        self.height = height ?? style.height
        self.viewProvider = nil
    }

    /// Build a fully custom native layout in code. `viewProvider` must return a real
    /// `NativeAdView` (GADNativeAdView) with the asset outlets you want connected
    /// (e.g. only `mediaView` for a video-only ad). The library binds the ad data, lets the
    /// SDK render AdChoices, and sets the root view controller — so it passes the AdMob
    /// validator exactly like the built-in xib layouts. You own all styling.
    public init(
        nativeViewModel: NativeAdViewModel,
        height: CGFloat,
        viewProvider: @escaping @MainActor () -> NativeAdView
    ) {
        self.nativeViewModel = nativeViewModel
        self.style = .nativeLargeMediaCtaBottom
        self.colorConfig = nil
        self.height = height
        self.viewProvider = viewProvider
    }

    @ViewBuilder
    public var body: some View {
        content
            .onAppear {
                assignRootViewController()
            }
            .onChange(of: nativeViewModel.nativeAd) { _ in
                assignRootViewController()
            }
    }

    @ViewBuilder
    private var content: some View {
        if nativeViewModel.nativeAd != nil {
            AdNativeView(
                nativeViewModel: nativeViewModel,
                style: style,
                colorConfig: colorConfig,
                viewProvider: viewProvider
            )
            .frame(height: height)
        } else if nativeViewModel.isLoading {
            ShimmerNativeLoadingView(style: style, height: height)
                .clipped()
        } else {
            EmptyView()
                .frame(height: 0)
        }
    }

    private func assignRootViewController() {
        guard let nativeAd = nativeViewModel.nativeAd else { return }
        
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

        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let rootVC = windowScene.windows.first(where: \.isKeyWindow)?.rootViewController {
                nativeAd.rootViewController = getTopVC(rootVC) ?? rootVC
            } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController {
                nativeAd.rootViewController = getTopVC(rootVC) ?? rootVC
            }
        }
    }
}

struct NativeContentView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NativeAdViewModel(adUnitID: "ca-app-pub-3940256099942544/3986624511") // Google test ID (preview only)
        
        NativeContentView(
            nativeViewModel: viewModel,
            style: .nativeLargeMediaCtaTop,
        )
        .padding()
    }
}
