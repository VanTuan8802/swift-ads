//
//  InterAdUtil.swift
//  AdmobSwitUI
//
//  Created by VanTuan8802 on 13/8/26.
//
//  Utility tập trung quản lý Interstitial Ad trong toàn app.
//  Mọi nơi muốn show inter đều gọi qua đây.
//

import Foundation
import swift_ads

// MARK: - AdKey

/// Tất cả các key quảng cáo trong app.
enum AdKey: String {
    case interSplash
    case interAll       // Dùng kèm InterAllExtraKey
    case nativeLanguage
    case nativeLanguageSelect
    case nativeIntro1
    case nativeIntro3
    case nativeHome
    case nativeCreate
    case openResume
    case nativeFull
    case nativeStart
    case openResumeStart
    case nativeAll
}

// MARK: - InterAllExtraKey

/// Sub-key cho .interAll — xác định vị trí cụ thể trong app show inter.
/// Khi dùng, AdKey tự động là `.interAll`.
enum InterAllExtraKey: String {
    case interProfile
    case interSettings
    case interPeriod
    case interHistory
    case interItem
    case interAdd
    case interTab
    case interBack
    case interStart
    case interWidget
    case interGoal
    case interClose
    case interIntro
}

// MARK: - InterAdUtil

/// Singleton quản lý việc show Interstitial Ad.
///
/// **Cách dùng:**
/// ```swift
/// // Tại các điểm trong app dùng interAll — chỉ truyền extraKey
/// InterAdUtil.shared.show(.interBack) {
///     navigationController?.popViewController(animated: true)
/// }
///
/// // Tại Splash, Intro... — chỉ truyền AdKey
/// InterAdUtil.shared.show(.interSplash) {
///     router.push(.home)
/// }
/// ```
final class AdUtil {

    static let shared = AdUtil()
    private init() {}

    // MARK: - Ad Unit ID map (hardcode từ AdUnitID.swift)

    /// Demo chỉ có 1 loại inter duy nhất — mọi key inter đều dùng AdUnitID.interstitial.
    private func adUnitID(for key: AdKey) -> String {
        switch key {
        case .interSplash, .interAll:
            return AdUnitID.interstitial
        case .openResume, .openResumeStart:
            return AdUnitID.appOpen
        case .nativeHome, .nativeCreate, .nativeFull, .nativeStart,
             .nativeAll, .nativeLanguage, .nativeLanguageSelect,
             .nativeIntro1, .nativeIntro3:
            return AdUnitID.native
        }
    }

    // MARK: - Overload 1: Dùng InterAllExtraKey → tự động key = .interAll

    /// Dùng tại các điểm cụ thể trong app (back, tab, settings...).
    /// AdKey tự động là `.interAll`.
    @MainActor
    func show(
        _ extraKey: InterAllExtraKey,
        forceShow: Bool = false,
        showLoading: Bool = true,
        onShowed: (() -> Void)? = nil,
        onDismissed: (() -> Void)? = nil,
        onFailed: (() -> Void)? = nil
    ) {
        showInter(
            key: .interAll,
            label: "interAll/\(extraKey.rawValue)",
            forceShow: forceShow,
            showLoading: showLoading,
            onShowed: onShowed,
            onDismissed: onDismissed,
            onFailed: onFailed
        )
    }

    // MARK: - Overload 2: Dùng AdKey trực tiếp (interSplash, interAll tường minh...)

    /// Dùng cho các AdKey riêng lẻ không cần extraKey (ví dụ: `.interSplash`).
    @MainActor
    func show(
        _ key: AdKey,
        forceShow: Bool = false,
        showLoading: Bool = true,
        onShowed: (() -> Void)? = nil,
        onDismissed: (() -> Void)? = nil,
        onFailed: (() -> Void)? = nil
    ) {
        showInter(
            key: key,
            label: key.rawValue,
            forceShow: forceShow,
            showLoading: showLoading,
            onShowed: onShowed,
            onDismissed: onDismissed,
            onFailed: onFailed
        )
    }

    // MARK: - Core

    @MainActor
    private func showInter(
        key: AdKey,
        label: String,
        forceShow: Bool,
        showLoading: Bool,
        onShowed: (() -> Void)?,
        onDismissed: (() -> Void)?,
        onFailed: (() -> Void)?
    ) {
        let adUnitID = adUnitID(for: key)

        log("▶️ [\(label)] Đang show inter...")

        AdsManager.shared.showInterstitialAd(
            adUnitID: adUnitID,
            onShowed: {
                self.log("✅ [\(label)] Ad đã hiển thị.")
                onShowed?()
            },
            onDismissed: {
                self.log("✅ [\(label)] Ad đã đóng.")
                onDismissed?()
            },
            onFailed: { error in
                self.log("❌ [\(label)] Thất bại: \(error.localizedDescription)")
                // Vẫn gọi onFailed để không block UX
                onFailed?()
            },
            forceShow: forceShow,
            showLoading: showLoading
        )
    }

    // MARK: - Private

    private func log(_ message: String) {
#if DEBUG
        print("InterAdUtil: \(message)")
#endif
    }
}
