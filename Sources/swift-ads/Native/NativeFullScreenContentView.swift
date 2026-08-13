//
//  NativeFullScreenContentView.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import SwiftUI
import GoogleMobileAds

/// A SwiftUI View that displays a NativeAd in full-screen layout.
/// Place this view in your layout hierarchy — it fills all available space.
///
/// Layout: background from colorConfig, large media center, icon + headline/body + CTA at bottom.
/// Optional close button (×) at top-right corner with callback.
/// All colors from AdsManager.shared.getNativeAdColorConfig().
///
/// Usage:
/// ```swift
/// NativeFullScreenContentView(
///     nativeViewModel: viewModel,
///     showCloseButton: true,
///     onCloseButtonTapped: { /* handle close */ }
/// )
/// ```
public struct NativeFullScreenContentView: View {
    @ObservedObject var nativeViewModel: NativeAdViewModel
    var showCloseButton: Bool
    var onCloseButtonTapped: (() -> Void)?
    var colorConfig: NativeAdColorConfig?

    public init(
        nativeViewModel: NativeAdViewModel,
        showCloseButton: Bool = true,
        onCloseButtonTapped: (() -> Void)? = nil,
        colorConfig: NativeAdColorConfig? = nil
    ) {
        self.nativeViewModel = nativeViewModel
        self.showCloseButton = showCloseButton
        self.onCloseButtonTapped = onCloseButtonTapped
        self.colorConfig = colorConfig
    }

    private var resolvedConfig: NativeAdColorConfig {
        colorConfig ?? AdsManager.shared.getNativeAdColorConfig()
    }

    public var body: some View {
        ZStack {
            resolvedConfig.backgroundColor.ignoresSafeArea()

            if nativeViewModel.nativeAd != nil {
                ZStack(alignment: .topTrailing) {
                    NativeFullScreenAdView(
                        nativeViewModel: nativeViewModel,
                        colorConfig: colorConfig
                    )
                    .ignoresSafeArea()

                    // Close button
                    if showCloseButton {
                        Button(action: {
                            onCloseButtonTapped?()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 16)
                    }
                }
            } else if nativeViewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Spacer()
                }
            }
        }
    }
}

struct NativeFullScreenContentView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = NativeAdViewModel(adUnitID: "ca-app-pub-3940256099942544/3986624511") // Google test ID (preview only)
        NativeFullScreenContentView(
            nativeViewModel: viewModel,
            showCloseButton: true
        )
    }
}
