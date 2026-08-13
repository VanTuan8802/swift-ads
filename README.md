# Swift Ads Package

Một Swift Package mạnh mẽ và dễ sử dụng để tích hợp Google AdMob vào ứng dụng iOS SwiftUI.

## 🚀 Tính năng

- **App Open Ads** - Quảng cáo khi mở ứng dụng
- **Interstitial Ads** - Quảng cáo toàn màn hình
- **Rewarded Ads** - Quảng cáo có thưởng
- **Rewarded Interstitial Ads** - Quảng cáo toàn màn hình có thưởng
- **Smart Preloading (V2)** - Cơ chế preload thông minh cho tất cả các loại quảng cáo với buffer size (opacity)
- **Banner Ads** - Quảng cáo banner với shimmer loading
- **Native Ads** - Quảng cáo gốc với shimmer loading và caching
- **Revenue Tracking** - Tự động theo dõi doanh thu quảng cáo (AdRevenueTracker)
- **Centralized Ad Management** - Quản lý tập trung interval (cho Interstitial) và thread-safety (@MainActor)
- **App Lifecycle Reactor** - Tự động quản lý hiển thị App Open Ad khi chuyển đổi giữa các trạng thái ứng dụng
- **Concurrency Safe** - Đảm bảo an toàn đa luồng trên toàn hệ thống
- **Internet Monitoring** - Tự động theo dõi và cập nhật trạng thái kết nối mạng

## 📦 Cài đặt

### Swift Package Manager

Repo là public trên GitHub nên không cần cấu hình xác thực — chỉ cần thêm package vào Xcode.

#### Thêm package vào Xcode

1. Trong Xcode, chọn **File > Add Package Dependencies**
2. Nhập URL: `https://github.com/VanTuan8802/swift-ads.git`
3. Chọn version và click **Add Package**

#### Hoặc khai báo trong `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/VanTuan8802/swift-ads.git", from: "1.0.0")
]
```

## 🔧 Khởi tạo

### 1. Import Package

```swift
import swift_ads
```

### 2. Khởi tạo AdsManager

Gọi trong `App.init()` hoặc sớm nhất khi app khởi động (sau `FirebaseApp.configure()` nếu dùng Firebase).

```swift
// Khởi tạo với cấu hình đầy đủ
AdsManager.shared.initialize(
    intervalShowInter: 15, // Thời gian chờ giữa 2 lần hiện Interstitial (giây)
    nativeAdColorConfig: NativeAdColorConfig(
        headlineColor: .white,
        bodyColor: .white,
        adColor: .white,
        adBackgroundColor: .color9B51F6,
        callToActionBackgroundColor: .color9B51F6,
        callToActionTextColor: .white
    )
)
```

### 3. Cấu hình Preload (Khuyên dùng)

Hệ thống cho phép preload quảng cáo vào bộ nhớ đệm để hiển thị tức thì khi cần.

```swift
// Khởi tạo App Open Ad với preload buffer
AdsManager.shared.initAppOpenAd(
    appOpenAdUnitId: "your-app-open-ad-unit-id",
    opacity: 1 // Số lượng ad sẽ được giữ trong bộ nhớ đệm
)

// Preload các loại quảng cáo khác
AdsManager.shared.preloadInterstitialAd(adUnitID: "inter-id", opacity: 1)
AdsManager.shared.preloadRewardedAd(adUnitID: "reward-id", opacity: 1)
AdsManager.shared.preloadRewardedInterstitialAd(adUnitID: "reward-inter-id", opacity: 1)
```

## 📱 Sử dụng các loại quảng cáo

Khi gọi các hàm `show`, hệ thống sẽ:
1. Kiểm tra kết nối Internet.
2. Kiểm tra xem có quảng cáo nào đang hiển thị không (tránh chồng chéo).
3. Kiểm tra Interval (đối với Interstitial).
4. **Ưu tiên lấy quảng cáo từ bộ đệm Preload** nếu có sẵn.
5. Nếu không có Preload, hệ thống sẽ thực hiện load mới và hiển thị (có kèm Loading view).

### App Open Ads

```swift
Button("Show App Open Ad") {
    AdsManager.shared.showAppOpenAd(
        adUnitID: "your-app-open-ad-unit-id"
    ) { 
        print("App Open Ad showed")
    } onDismissed: {
        print("App Open Ad dismissed")
    } onFailed: { error in
        print("App Open Ad failed: \(error)")
    }
}
```

### Interstitial Ads

```swift
Button("Show Interstitial") {
    AdsManager.shared.showInterstitialAd(
        adUnitID: "your-interstitial-ad-unit-id"
    ) { 
        print("Interstitial showed")
    } onDismissed: {
        print("Interstitial dismissed")
    } onFailed: { error in
        print("Interstitial failed: \(error)")
    }
}
```

### Rewarded Ads

```swift
Button("Show Rewarded Ad") {
    AdsManager.shared.showRewardedAd(
        adUnitID: "your-rewarded-ad-unit-id"
    ) { 
        print("Rewarded ad showed")
    } onDismissed: { wasRewarded in
        if wasRewarded {
            print("User earned reward!")
            // Xử lý thưởng cho user
        }
    } onFailed: { error in
        print("Rewarded ad failed: \(error)")
    } onRewarded: {
        print("Reward granted")
    }
}
```

### Rewarded Interstitial Ads

```swift
Button("Show Rewarded Interstitial") {
    AdsManager.shared.showRewardedInterstitialAd(
        adUnitID: "your-rewarded-interstitial-ad-unit-id"
    ) { 
        print("Rewarded Interstitial showed")
    } onDismissed: { wasRewarded in
        if wasRewarded {
            print("User earned reward!")
            // Xử lý thưởng cho user
        }
    } onFailed: { error in
        print("Rewarded Interstitial failed: \(error)")
    } onRewarded: {
        print("Reward granted")
    }
}
```

### Banner Ads

```swift
// Cách sử dụng đơn giản
BannerContentView(adUnitID: "your-banner-ad-unit-id")
// Banner tự động điều chỉnh size theo màn hình
// Không cần set width, chỉ cần set height
```

### Native Ads

```swift
// Tạo ViewModel
let nativeVM = NativeAdViewModel(adUnitID: "your-native-ad-unit-id")

// Sử dụng NativeContentView với shimmer loading
NativeContentView(
    nativeViewModel: nativeVM,
    style: .nativeLargeMediaCtaBottom,
    height: 300
)

// Với custom colors
let customColors = NativeAdColorConfig(
    headlineColor: .white,
    bodyColor: .white,
    adColor: .white,
    adBackgroundColor: .color9B51F6,
    callToActionBackgroundColor: .color9B51F6,
    callToActionTextColor: .white
)

NativeContentView(
    nativeViewModel: nativeVM,
    style: .nativeLargeMediaCtaBottom,
    colorConfig: customColors,
    height: 300
)

// Đừng quên gọi load
nativeVM.refreshAd()
```

## 🧩 Custom Native Ads

> 📖 Hướng dẫn chi tiết + quy tắc validator: xem [CUSTOM_NATIVE_ADS.md](CUSTOM_NATIVE_ADS.md)

Bạn có thể tự thiết kế layout native **bằng `GADNativeAdView` thật** — giống hệt các template
dựng sẵn nên **đạt AdMob Native Ad Validator**. Thư viện lo load, caching, revenue tracking,
bind dữ liệu ad, AdChoices và rootViewController. Có **2 cách**:

### Cách 1 — Swift code (`viewProvider`) — linh hoạt nhất

Truyền `viewProvider` trả về một `NativeAdView` bạn tự dựng, chỉ nối những outlet bạn cần
(vd: chỉ `mediaView` cho native chỉ-video, không title/button). Bạn toàn quyền style.

```swift
let nativeVM = NativeAdViewModel(adUnitID: "your-native-ad-unit-id")

NativeContentView(nativeViewModel: nativeVM, height: 360) {
    let adView = NativeAdView()

    let media = MediaView()
    media.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(media)
    adView.mediaView = media                 // nối outlet media

    let headline = UILabel()
    headline.font = .boldSystemFont(ofSize: 17)
    headline.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(headline)
    adView.headlineView = headline           // nối outlet headline

    let cta = UIButton(type: .system)
    cta.isUserInteractionEnabled = false     // SDK tự xử lý click
    cta.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(cta)
    adView.callToActionView = cta            // nối outlet CTA

    // ... Auto Layout cho media / headline / cta trong adView ...
    return adView
}

nativeVM.refreshAd()
```

Thư viện sẽ tự gán `headline`, `body`, `icon`, `mediaContent`, tiêu đề CTA vào đúng outlet
bạn đã nối; outlet nào không nối thì bỏ qua (nên **native chỉ-video** = chỉ nối `mediaView`).

> Lưu ý: chỉ cần đảm bảo mọi asset nằm **trong** khung `NativeAdView` (đặt `height` đủ lớn) và
> nên có nhãn "Ad"/AdChoices để hợp lệ chính sách Google.

### Cách 2 — XIB (`.custom(nibName:)`) — thiết kế trong Interface Builder

Tự dựng `.xib` trong Interface Builder (root view là `NativeAdView`, nối các outlet
`headlineView`, `bodyView`, `iconView`, `mediaView`, `callToActionView` tùy ý; thêm `UILabel`
tag 9 nếu muốn badge "Ad"). Sau đó dùng style `.custom`:

```swift
NativeContentView(
    nativeViewModel: nativeVM,
    style: .custom(nibName: "MyNativeAdView", bundle: .main, height: 320)
)
```

Cả 2 cách đều là `GADNativeAdView` thật nên AdChoices được SDK tự đặt và pass validator như
các native dựng sẵn.

## 🎨 Tùy chỉnh Native Ad Colors

### Sử dụng NativeAdColorConfig

```swift
let customColors = NativeAdColorConfig(
    headlineColor: .white,
    bodyColor: .white,
    adColor: .white,
    adBackgroundColor: .color9B51F6,
    callToActionBackgroundColor: .color9B51F6,
    callToActionTextColor: .white
)
```

### Sử dụng copyWith để thay đổi từng phần

```swift
let defaultColors = NativeAdColorConfig()
let customColors = defaultColors.copyWith(
    headlineColor: .white,
    adBackgroundColor: .color9B51F6,
    callToActionBackgroundColor: .color9B51F6
)
```

## 💰 Revenue Tracking

### Cách 1 (khuyến nghị): Bật analytics fan-out có sẵn (Adjust + Firebase + Meta)

Package đã tích hợp sẵn bộ fan-out revenue: mỗi ad impression có doanh thu tự động bắn
**Firebase/GA4** (event `ad_revenue`), **Adjust** (`ADJAdRevenue` + event `ad_impression_custom`)
và **Meta** (standard event `AdImpression`). App chỉ cần truyền token:

```swift
// Gọi SAU khi user trả lời ATT prompt (Meta cần trạng thái ATT).
// FirebaseApp.configure() là việc của app, chạy trước đó.
AdsManager.shared.initialize(
    intervalShowInter: 15,
    analytics: AdsAnalyticsConfig(
        adjustAppToken: "gw2umdeaslc0",          // rỗng → skip Adjust
        adjustAdImpressionEventToken: "1j8xmz",  // rỗng → skip event custom
        adjustPurchaseEventToken: ""             // rỗng → trackPurchase skip Adjust
    )
)
```

Nếu flow app init ads TRƯỚC ATT prompt, gọi riêng phần analytics tại thời điểm đúng:

```swift
await ATTrackingManager.requestTrackingAuthorization()
AdsAnalytics.shared.start(config: AdsAnalyticsConfig(adjustAppToken: "..."))
```

Kèm sẵn API cho IAP:

```swift
AdsAnalytics.shared.trackPurchase(productId:transactionId:revenue:currency:)
AdsAnalytics.shared.trackSubscription(productId:price:currency:transactionId:transactionDate:salesRegion:)
```

Meta SDK tự init nếu Info.plist có `FacebookAppID` thật (còn placeholder → tự skip).
Nhớ tắt `FacebookAutoInitEnabled` + `FacebookAutoLogAppEventsEnabled` +
`FacebookAdvertiserIDCollectionEnabled` trong Info.plist để không thu thập gì trước consent.

### Cách 2: Truyền closure tuỳ ý

Muốn tự xử lý (server riêng, analytics khác) — truyền handler khi khởi tạo AdsManager,
chạy song song với `analytics` ở trên nếu bật cả hai:

```swift
AdsManager.shared.initialize(
    intervalShowInter: 15,
    onAdRevenue: { adValue, adUnit, adType in
        // Xử lý revenue data
        print("💰 Revenue: \(adValue.value) \(adValue.currencyCode) | \(adUnit) | \(adType.rawValue)")
        // Gửi đến analytics / server...
    }
)
```

Hoặc gán trực tiếp bất kỳ lúc nào:

```swift
AdRevenueTracker.shared.onAdRevenue = { adValue, adUnit, adType in
    // ...
}
```

### Cách 3 (legacy): Dùng delegate

> Lưu ý: `delegate` là `weak`, app phải tự giữ strong reference (ví dụ singleton), nếu không sẽ bị deallocate và mất event.

```swift
class MyRevenueLogger: AdRevenueDelegate {
    static let shared = MyRevenueLogger()
    
    private init() {
        AdRevenueTracker.shared.delegate = self
    }
    
    func didTrackAdRevenue(adValue: AdValue, adUnit: String, adType: AdType) {
        print("💰 Revenue: \(adValue.value) \(adValue.currencyCode)")
    }
}

// Khởi tạo trong app
.onAppear {
    _ = MyRevenueLogger.shared
}
```

## 🎨 Shimmer Loading

### Native Ads với Shimmer

```swift
// NativeContentView tự động hiển thị shimmer khi loading
NativeContentView(
    nativeViewModel: nativeViewModel,
    style: .large,
    height: 300
)
```

### Banner Ads với Shimmer

```swift
// BannerContentView tự động hiển thị shimmer khi loading
BannerContentView(adUnitID: "your-banner-ad-unit-id")
    .frame(height: 50)
```

## ⚙️ Cấu hình nâng cao

### Cơ chế Preloading V2

Tất cả các loại quảng cáo (App Open, Inter, Reward) đều hỗ trợ preloading thông qua các lớp chuyên biệt (ví dụ: `InterPreload`, `RewardsPreload`).
- **Buffer Mode**: Bạn có thể chỉ định `opacity` (số lượng ad) để hệ thống tự động duy trì trong bộ nhớ đệm.
- **Auto-refill**: Khi một ad được sử dụng, hệ thống sẽ tự động preload ad mới để lấp đầy buffer.

### Quản lý Interval (Interstitial Only)

Chỉ riêng Interstitial Ads được áp dụng cơ chế `intervalShowInter`.
- `AdsManager` theo dõi `interLastTime` toàn cục.
- Các loại Rewarded Ads hoặc App Open Ads sẽ không bị chặn bởi interval này để đảm bảo trải nghiệm người dùng và doanh thu.

### Thread Safety

Toàn bộ logic xử lý hiển thị, cập nhật trạng thái và callback đều được đánh dấu với `@MainActor`, đảm bảo an toàn tuyệt đối khi tương tác với UI.

## 📋 Requirements

- iOS 14.0+
- Swift 6.0+
- Xcode 16.0+
- Google Mobile Ads SDK 12.8.0+

## 🔧 API Reference

- `initialize(intervalShowInter:nativeAdColorConfig:animationFiles:)` - Khởi tạo manager
- `initAppOpenAd(appOpenAdUnitId:opacity:autoEnable:)` - Khởi tạo app open ad với preload
- `preloadInterstitialAd(adUnitID:opacity:)` - Đưa ad vào bộ đệm Interstitial
- `preloadRewardedAd(adUnitID:opacity:)` - Đưa ad vào bộ đệm Rewarded
- `preloadRewardedInterstitialAd(adUnitID:opacity:)` - Đưa ad vào bộ đệm Rewarded Interstitial
- `showAppOpenAd(adUnitID:onShowed:onDismissed:onFailed:showLoading:)` - Hiển thị app open ad
- `showInterstitialAd(adUnitID:onShowed:onDismissed:onFailed:forceShow:showLoading:)` - Hiển thị interstitial
- `showRewardedAd(adUnitID:onShowed:onDismissed:onFailed:onRewarded:showLoading:)` - Hiển thị rewarded ad
- `showRewardedInterstitialAd(adUnitID:onShowed:onDismissed:onFailed:onRewarded:showLoading:)` - Hiển thị rewarded interstitial
