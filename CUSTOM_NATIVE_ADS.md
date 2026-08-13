# Custom Native Ads — Hướng dẫn tích hợp

Tài liệu này hướng dẫn cách tự thiết kế layout Native Ad trong `swift-ads`. Cả 2 cách đều
tạo ra **`GADNativeAdView` thật** nên **đạt AdMob Native Ad Validator** (giống các native
dựng sẵn). Thư viện tự lo: load ad, caching, revenue tracking, bind dữ liệu, AdChoices,
và `rootViewController`.

> Ví dụ chạy được nằm ở `Demo/AdmobSwitUI/AdmobSwitUI/ContentView.swift` → màn **`CustomNativeScreen`**.

---

## TL;DR — chọn cách nào?

| | File thiết kế | API | Khi nào dùng |
|---|---|---|---|
| **Cách 1 — Swift code** | `.swift` (code) | `NativeContentView(nativeViewModel:height:viewProvider:)` | Linh hoạt nhất, không cần xib, dựng layout bằng Auto Layout trong code |
| **Cách 2 — XIB** | `.xib` (Interface Builder) | `NativeContentView(nativeViewModel:style: .custom(nibName:bundle:height:))` | Thích kéo-thả trong IB, tái dùng layout sẵn |

Cả hai: bạn chỉ cần **nối đúng outlet** (`headlineView`, `mediaView`, `iconView`,
`bodyView`, `callToActionView`, …). Outlet nào không nối thì thư viện bỏ qua → có thể làm
native tối giản (vd media + title).

---

## Bảng outlet → asset (tự custom theo ý)

Muốn hiện asset nào thì tạo view tương ứng rồi gán vào outlet. **Không nối = không hiện.**
Thư viện tự đổ dữ liệu, bạn chỉ lo layout & style.

| Outlet (gán vào `adView`) | Kiểu view nên dùng | Hiện gì | Bắt buộc? |
|---|---|---|---|
| `headlineView` | `UILabel` | Tiêu đề quảng cáo | ✅ Bắt buộc (chính sách Google) |
| `mediaView` | `MediaView` | Ảnh/video chính | ✅ Nên có (native lớn) |
| `iconView` | `UIImageView` | Icon app/thương hiệu | Tuỳ chọn |
| `bodyView` | `UILabel` | Mô tả | Tuỳ chọn |
| `callToActionView` | `UIButton` | Nút CTA ("Install"…) | Tuỳ chọn |
| `adChoicesView` | `AdChoicesView` | Overlay AdChoices | Tự chèn nếu bỏ trống |
| *(badge "Ad")* | `UILabel` tự đặt | Nhãn "Ad" tĩnh | Nên có (attribution) |

> **Tối giản nhất hợp lệ** = `headlineView` + `mediaView` + badge "Ad" + AdChoices.
> Cách code (`viewProvider`) thư viện **tự chèn AdChoices**; bạn chỉ cần thêm badge "Ad".

---

## Cách 1 — Swift code (`viewProvider`)

Truyền closure trả về một `NativeAdView` bạn tự dựng. Bạn **toàn quyền layout & style**
(thư viện KHÔNG áp `NativeAdColorConfig` cho cách này).

```swift
import swift_ads
import GoogleMobileAds

let nativeVM = NativeAdViewModel(adUnitID: "your-native-ad-unit-id")

NativeContentView(nativeViewModel: nativeVM, height: 360) {
    let adView = NativeAdView()

    // MEDIA (chừa lề để không đè AdChoices ở góc trên-phải)
    let media = MediaView()
    media.contentMode = .scaleAspectFill
    media.clipsToBounds = true
    media.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(media)
    adView.mediaView = media

    // HEADLINE (đặt DƯỚI media, không chồng lên media)
    let headline = UILabel()
    headline.font = .boldSystemFont(ofSize: 17)
    headline.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(headline)
    adView.headlineView = headline

    // CTA (SDK tự xử lý click → tắt userInteraction)
    let cta = UIButton(type: .system)
    cta.isUserInteractionEnabled = false
    cta.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(cta)
    adView.callToActionView = cta

    NSLayoutConstraint.activate([
        media.topAnchor.constraint(equalTo: adView.topAnchor, constant: 12),
        media.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
        media.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
        media.heightAnchor.constraint(equalToConstant: 200),

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

// Nhớ gọi load:
nativeVM.refreshAd()
```

Thư viện tự gán: `headline`, `body`, `icon`, `mediaContent`, tiêu đề CTA vào outlet tương ứng,
và **tự chèn `AdChoicesView`** (góc trên-phải) nếu bạn chưa tự thêm.

### Ví dụ "media nổi bật + title nhỏ" (gần với "video native")

Media to ở trên, title nhỏ ở DƯỚI (không overlay). Google bắt buộc có headline nên
**không thể làm native chỉ-media-không-title**.

```swift
NativeContentView(nativeViewModel: videoVM, height: 240) {
    let adView = NativeAdView()
    adView.backgroundColor = .black

    let media = MediaView()
    media.contentMode = .scaleAspectFill
    media.clipsToBounds = true
    media.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(media)
    adView.mediaView = media

    let headline = UILabel()
    headline.font = .systemFont(ofSize: 14, weight: .semibold)
    headline.textColor = .white
    headline.translatesAutoresizingMaskIntoConstraints = false
    adView.addSubview(headline)
    adView.headlineView = headline

    NSLayoutConstraint.activate([
        media.topAnchor.constraint(equalTo: adView.topAnchor, constant: 12),
        media.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
        media.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
        media.heightAnchor.constraint(equalToConstant: 170),

        headline.topAnchor.constraint(equalTo: media.bottomAnchor, constant: 10),
        headline.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
        headline.trailingAnchor.constraint(lessThanOrEqualTo: adView.trailingAnchor, constant: -12),
        headline.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor, constant: -12),
    ])
    return adView
}
```

> Muốn video thật: dùng ad unit native video (vd test `ca-app-pub-3940256099942544/2521693316`).
> Test ad video có thể không fill trên simulator — không phải lỗi code.

---

## Cách 2 — XIB (`.custom(nibName:)`)

1. Tạo file `.xib` trong Interface Builder.
2. Đặt **root view** là `NativeAdView` (Custom Class = `GADNativeAdView`).
3. Kéo các subview và nối outlet tùy ý: `headlineView`, `bodyView`, `iconView`,
   `mediaView` (Custom Class `GADMediaView`), `callToActionView`.
4. (Tuỳ chọn) Thêm `UILabel` text "Ad", set **tag = 9** nếu muốn thư viện style badge "Ad".
5. Dùng:

```swift
NativeContentView(
    nativeViewModel: nativeVM,
    style: .custom(nibName: "MyNativeAdView", bundle: .main, height: 320)
)
```

> Với cách xib, thư viện CÓ áp `NativeAdColorConfig` (màu headline/body/CTA, badge tag-9).

---

## ⚠️ Quy tắc bắt buộc của Google (để pass Validator)

AdMob có **Native Ad Validator** (chỉ hiện ở test mode) bắt 3 lỗi hay gặp:

1. **"Advertiser assets outside native ad view"** — mọi asset phải nằm **TRONG** khung
   `NativeAdView`. → Đặt `height` **đủ lớn** để content không tràn ra ngoài.

2. **"Assets can not be placed on top of another asset"** — các asset (đã nối outlet)
   **không được đè lên nhau**. Vd: title KHÔNG được overlay lên media → đặt title **dưới/cạnh**
   media. Đặc biệt **media full-bleed (sát mép)** sẽ bị AdChoices (góc trên-phải) đè lên →
   hãy **chừa lề** cho media (vd inset 12pt) để góc trống cho AdChoices.
   *(Label trang trí không-phải-asset như badge "Ad" tĩnh thì không bị tính.)*

3. **"Ad attribution missing"** — phải có **AdChoices overlay** + thuộc tính "Ad". Thư viện
   tự chèn `AdChoicesView` cho native dựng bằng code; với xib thì SDK tự đặt qua
   `preferredAdChoicesPosition` (đã cấu hình sẵn trong `NativeAdViewModel`).

**Hệ quả quan trọng:** native ad **bắt buộc** hiển thị tối thiểu **Headline + AdChoices +
thuộc tính "Ad"**. Vì vậy **không tồn tại native "chỉ video/ảnh, không title"** — sẽ luôn bị
validator báo lỗi. Form hợp lệ gần nhất là **media to + title nhỏ**.

---

## Checklist nhanh khi tự dựng native

- [ ] Root là `NativeAdView`, đã nối ít nhất `mediaView` + `headlineView`.
- [ ] `height` ≥ chiều cao thực của layout (asset không tràn ra ngoài).
- [ ] Không có asset nào đè lên asset khác.
- [ ] Media **chừa lề** ở góc trên-phải cho AdChoices (đừng full-bleed sát mép).
- [ ] CTA (nếu có): `isUserInteractionEnabled = false` (SDK tự xử lý click).
- [ ] Gọi `nativeVM.refreshAd()` để load.

---

## Tham chiếu API

- `NativeContentView(nativeViewModel:style:colorConfig:height:)` — native theo style dựng sẵn
  hoặc `.custom(nibName:bundle:height:)`.
- `NativeContentView(nativeViewModel:height:viewProvider:)` — native dựng bằng code.
- `NativeAdViewStyle.custom(nibName:bundle:height:)` — nạp layout từ xib của bạn.
- `NativeAdViewModel(adUnitID:)` + `.refreshAd()` — quản lý load ad.
