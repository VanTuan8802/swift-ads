//
//  ContentView.swift
//  AdmobSwitUI
//
//  Created by VanTuan8802 on 13/8/26.
//

import SwiftUI
import GoogleMobileAds
import swift_ads

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: AppOpenScreen()) {
                    Text("App Open Ad Test")
                }
                
                NavigationLink(destination: InterstitialScreen()) {
                    Text("Interstitial Ad Util")
                }
                
                NavigationLink(destination: RewardedScreen()) {
                    Text("Rewarded & Other Ads (AdsManager)")
                }
                
                NavigationLink(destination: NativeFullScreenScreen()) {
                    Text("Native Full Screen Ad")
                }
                
                NavigationLink(destination: NativeAndBannerScreen()) {
                    Text("Native & Banner Ads")
                }

                NavigationLink(destination: CustomNativeScreen()) {
                    Text("Custom Native Ads")
                }
            }
            .navigationTitle("Ads Demo")
        }
    }
}

// MARK: - App Open Screen
struct AppOpenScreen: View {
    @State private var showSheet = false

    var body: some View {
        List {
            Section(header: Text("Test App Open over Modal Screen")) {
                Button("🧪 Mở Sheet → show App Open Ad") {
                    showSheet = true
                }
                .sheet(isPresented: $showSheet) {
                    AppOpenTestView(isSheet: true)
                }
            }
        }
        .navigationTitle("App Open Ad")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Interstitial Screen
struct InterstitialScreen: View {
    var body: some View {
        List {
            Section(header: Text("InterAdUtil (Recommended)")) {
                Button("Inter - Splash Screen") {
                    AdUtil.shared.show(.interSplash) {
                        print("✅ Điều hướng sau splash inter")
                    }
                }

                Button("Inter - Back") {
                    AdUtil.shared.show(.interBack) {
                        print("✅ Điều hướng sau back inter")
                    }
                }

                Button("Inter - Settings") {
                    AdUtil.shared.show(.interSettings) {
                        print("✅ Điều hướng sau settings inter")
                    }
                }

                Button("Inter - Force Show") {
                    AdUtil.shared.show(.interSplash, forceShow: true) {
                        print("✅ Force inter đã đóng")
                    }
                }
            }
        }
        .navigationTitle("Interstitial Ad Util")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Rewarded & Direct Ads Screen
struct RewardedScreen: View {
    var body: some View {
        List {
            Section(header: Text("AdsManager trực tiếp")) {
                Button("Show App Open (Preload)") {
                    AdsManager.shared.showAppOpenAd(adUnitID: AdUnitID.appOpen) {
                        print("App Open showed")
                    }
                }

                Button("Show Rewarded (Preload)") {
                    AdsManager.shared.showRewardedAd(adUnitID: AdUnitID.rewarded) {
                        print("Rewarded showed")
                    } onRewarded: {
                        print("User received reward!")
                    }
                }

                Button("Show Rewarded Interstitial (Preload)") {
                    AdsManager.shared.showRewardedInterstitialAd(adUnitID: AdUnitID.rewardedInterstitial) {
                        print("Rewarded Interstitial showed")
                    } onRewarded: {
                        print("User received reward from Inter!")
                    }
                }
            }
        }
        .navigationTitle("Rewarded & Others")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Native Full Screen Screen
struct NativeFullScreenScreen: View {
    @StateObject private var nativeFullScreenViewModel = NativeAdViewModel(adUnitID: AdUnitID.nativeFullScreen)
    @State private var showNativeFullScreen = false
    @State private var showNativeFullScreenNoClose = false

    var body: some View {
        ZStack {
            List {
                Section(header: Text("Native Full Screen")) {
                    Button("Show Native Full Screen (In View)") {
                        nativeFullScreenViewModel.refreshAd()
                        showNativeFullScreen = true
                    }

                    Button("Show Native Full Screen (No Close)") {
                        nativeFullScreenViewModel.refreshAd()
                        showNativeFullScreenNoClose = true
                    }

                    Button("Show Native Full Screen (Popup)") {
                        AdsManager.shared.showNativeFullScreenAd(
                            adUnitID: AdUnitID.nativeFullScreen
                        ) {
                            print("✅ Native Full Screen Popup showed")
                        } onDismissed: {
                            print("✅ Native Full Screen Popup dismissed")
                        } onFailed: { error in
                            print("❌ Native Full Screen Popup failed: \(error)")
                        } onCloseButtonTapped: {
                            print("✅ Popup close button tapped!")
                        }
                    }
                }
            }
            .navigationTitle("Native Full Screen")
            .navigationBarTitleDisplayMode(.inline)

            if showNativeFullScreen {
                NativeFullScreenContentView(
                    nativeViewModel: nativeFullScreenViewModel,
                    showCloseButton: true,
                    onCloseButtonTapped: {
                        print("✅ Close button tapped!")
                        showNativeFullScreen = false
                    }
                )
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(1)
            }

            if showNativeFullScreenNoClose {
                NativeFullScreenContentView(
                    nativeViewModel: nativeFullScreenViewModel,
                    showCloseButton: false
                )
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

// MARK: - Custom Native Screen
// Demo 2 cách custom native, đều ra GADNativeAdView thật (pass validator):
//   • Cách XIB    : NativeContentView(style:) — layout dựng từ file .xib (Interface Builder).
//                   Built-in style, hoặc xib của bạn qua .custom(nibName:).
//   • Cách SWIFT  : NativeContentView(viewProvider:) — dựng layout bằng code Swift.
struct CustomNativeScreen: View {
    @StateObject private var xibVM = NativeAdViewModel(adUnitID: AdUnitID.native)
    @StateObject private var customVM = NativeAdViewModel(adUnitID: AdUnitID.native)
    // Dùng unit native ảnh cho ổn định khi demo. Đổi sang AdUnitID.nativeVideo nếu muốn video thật.
    @StateObject private var videoVM = NativeAdViewModel(adUnitID: AdUnitID.native)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Button("Reload") {
                    xibVM.refreshAd()
                    customVM.refreshAd()
                    videoVM.refreshAd()
                }
                .buttonStyle(.bordered)

                // ===== CÁCH 1: XIB (file .xib) =====
                // Layout dựng trong Interface Builder. Đây là style dựng sẵn của thư viện;
                // để dùng xib RIÊNG của bạn: style: .custom(nibName: "TenXib", bundle: .main, height: ...)
                Text("① XIB (.xib file)")
                    .font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                NativeContentView(
                    nativeViewModel: xibVM,
                    style: .nativeLargeMediaCtaBottom
                )
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)

                // ===== CÁCH 2: SWIFT CODE (viewProvider) =====
                // Dựng GADNativeAdView bằng code. Toàn quyền layout & style.
                Text("② Swift code (viewProvider)")
                    .font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                NativeContentView(nativeViewModel: customVM, height: 360) {
                    CustomNativeScreen.makeCustomNativeAdView()
                }
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)

                // ===== CÁCH 2 (tt): SWIFT CODE — media lớn + title nhỏ =====
                // Google bắt buộc có headline + AdChoices, nên không thể "chỉ media không title".
                Text("③ Swift code — media lớn + title nhỏ")
                    .font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                NativeContentView(nativeViewModel: videoVM, height: 240) {
                    CustomNativeScreen.makeVideoNativeAdView()
                }
                .cornerRadius(16)
            }
            .padding()
        }
        .navigationTitle("Custom Native")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            xibVM.refreshAd()
            customVM.refreshAd()
            videoVM.refreshAd()
        }
    }

    /// A fully custom native layout in code: big media on top, headline + CTA below, plus an
    /// "Ad" attribution badge. AdChoices is auto-placed by the SDK.
    @MainActor
    static func makeCustomNativeAdView() -> NativeAdView {
        let adView = NativeAdView()
        adView.backgroundColor = .clear

        let media = MediaView()
        media.contentMode = .scaleAspectFill
        media.clipsToBounds = true
        media.layer.cornerRadius = 12
        media.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(media)
        adView.mediaView = media

        let adBadge = makeAdBadge()
        adView.addSubview(adBadge)

        let headline = UILabel()
        headline.font = .systemFont(ofSize: 17, weight: .bold)
        headline.numberOfLines = 2
        headline.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(headline)
        adView.headlineView = headline

        let cta = UIButton(type: .system)
        cta.backgroundColor = .systemPurple
        cta.setTitleColor(.white, for: .normal)
        cta.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        cta.layer.cornerRadius = 10
        cta.isUserInteractionEnabled = false
        cta.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(cta)
        adView.callToActionView = cta

        NSLayoutConstraint.activate([
            media.topAnchor.constraint(equalTo: adView.topAnchor, constant: 12),
            media.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            media.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            media.heightAnchor.constraint(equalToConstant: 200),

            adBadge.topAnchor.constraint(equalTo: media.topAnchor, constant: 8),
            adBadge.leadingAnchor.constraint(equalTo: media.leadingAnchor, constant: 8),
            adBadge.widthAnchor.constraint(equalToConstant: 26),
            adBadge.heightAnchor.constraint(equalToConstant: 18),

            headline.topAnchor.constraint(equalTo: media.bottomAnchor, constant: 12),
            headline.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            headline.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),

            cta.topAnchor.constraint(equalTo: headline.bottomAnchor, constant: 12),
            cta.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            cta.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            cta.heightAnchor.constraint(equalToConstant: 44),
            cta.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor, constant: -12),
        ])

        return adView
    }

    /// Video/media-prominent: big media on top + a small headline row BELOW it.
    /// Assets must NOT overlap each other, so the title sits under the media (not on top).
    /// (Google requires a headline + AdChoices, so we keep a minimal title.)
    @MainActor
    static func makeVideoNativeAdView() -> NativeAdView {
        let adView = NativeAdView()
        adView.backgroundColor = .black

        let media = MediaView()
        media.contentMode = .scaleAspectFill
        media.clipsToBounds = true
        media.layer.cornerRadius = 12
        media.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(media)
        adView.mediaView = media

        let adBadge = makeAdBadge()
        adView.addSubview(adBadge)

        let headline = UILabel()
        headline.font = .systemFont(ofSize: 14, weight: .semibold)
        headline.textColor = .white
        headline.numberOfLines = 1
        headline.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(headline)
        adView.headlineView = headline

        NSLayoutConstraint.activate([
            // Media is inset (leaves the top-right corner free for the AdChoices overlay so
            // they don't overlap — that's why this passes the validator).
            media.topAnchor.constraint(equalTo: adView.topAnchor, constant: 12),
            media.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            media.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            media.heightAnchor.constraint(equalToConstant: 170),

            // Headline row sits BELOW the media — no overlap with any asset.
            adBadge.topAnchor.constraint(equalTo: media.bottomAnchor, constant: 10),
            adBadge.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            adBadge.widthAnchor.constraint(equalToConstant: 26),
            adBadge.heightAnchor.constraint(equalToConstant: 18),

            headline.centerYAnchor.constraint(equalTo: adBadge.centerYAnchor),
            headline.leadingAnchor.constraint(equalTo: adBadge.trailingAnchor, constant: 8),
            headline.trailingAnchor.constraint(lessThanOrEqualTo: adView.trailingAnchor, constant: -12),
            headline.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor, constant: -12),
        ])

        return adView
    }

    @MainActor
    private static func makeAdBadge() -> UILabel {
        let adBadge = UILabel()
        adBadge.text = "Ad"
        adBadge.font = .systemFont(ofSize: 11, weight: .bold)
        adBadge.textColor = .white
        adBadge.backgroundColor = .systemOrange
        adBadge.textAlignment = .center
        adBadge.layer.cornerRadius = 4
        adBadge.clipsToBounds = true
        adBadge.translatesAutoresizingMaskIntoConstraints = false
        return adBadge
    }
}

// MARK: - Native & Banner Screen
struct NativeAndBannerScreen: View {
    @StateObject private var nativeLargeViewModel = NativeAdViewModel(adUnitID: AdUnitID.native)
    @StateObject private var nativeNormalViewModel = NativeAdViewModel(adUnitID: AdUnitID.native)
    @State private var hiddenNative = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Button("Reload Native") {
                    nativeLargeViewModel.refreshAd()
                    nativeNormalViewModel.refreshAd()
                }
                .buttonStyle(.bordered)

                Button("Toggle Native") {
                    hiddenNative.toggle()
                }
                .buttonStyle(.borderedProminent)

                BannerContentView(adUnitID: AdUnitID.adaptiveBanner)

                if !hiddenNative {
                    NativeContentView(
                        nativeViewModel: nativeLargeViewModel,
                        style: .nativeLargeMediaCtaTop
                    )
                    .background(Color(UIColor.secondarySystemBackground))

                    NativeContentView(
                        nativeViewModel: nativeNormalViewModel,
                        style: .nativeNormalMediaCtaTop
                    )
                    .background(Color(UIColor.secondarySystemBackground))
                }
            }
            .padding()
        }
        .navigationTitle("Native & Banner")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            nativeLargeViewModel.refreshAd()
            nativeNormalViewModel.refreshAd()
        }
    }
}

// MARK: - App Open Test View (dùng cho cả navigation push và sheet)

/// Màn hình test App Open Ad — dùng được ở 2 dạng:
/// - NavigationLink push (isSheet = false)
/// - Sheet modal pageSheet (isSheet = true)
struct AppOpenTestView: View {
    var isSheet: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text(isSheet ? "Sheet đang mở (không full màn hình)" : "Màn hình mới (Navigation Push)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Divider()

            Text("Bấm nút bên dưới để show App Open Ad.\nNếu fix đúng → ad hiện lên trên màn hình này.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("🚀 Show App Open Ad") {
                AdsManager.shared.showAppOpenAd(adUnitID: AdUnitID.appOpen) {
                    print("✅ App Open showed")
                }
            }
            .buttonStyle(.borderedProminent)

            if isSheet {
                Button("❌ Đóng Sheet") {
                    dismiss()
                }
                .foregroundColor(.red)
            }

            Spacer()
        }
        .padding(.top, 32)
        .navigationTitle("Test App Open")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

