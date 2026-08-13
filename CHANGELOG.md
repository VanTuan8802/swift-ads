# Changelog

Tất cả những thay đổi quan trọng trong package `swift-ads` sẽ được ghi lại trong file này.

## [Unreleased]

### Added
- **AdsAnalytics**: fan-out revenue tích hợp sẵn tới Adjust + Firebase/GA4 + Meta (`AdsAnalyticsConfig`, `AdsAnalytics.start(config:)`, `trackPurchase`, `trackSubscription`) — app không cần copy module analytics riêng
- `onAdRevenue` closure trên `AdRevenueTracker` + tham số `onAdRevenue`/`analytics` trong `AdsManager.initialize(...)` — không cần tạo class delegate riêng cho mỗi app
- Dependencies mới: FirebaseAnalytics (≥11.0), AdjustSdk (≥5.0), FacebookCore (≥18.0)

### Changed
- `AdsManager.initialize(...)` giờ là `@MainActor`
- **BREAKING**: `NativeAdViewModel(adUnitID:)` không còn default test ID — bắt buộc truyền tường minh, tránh app quên ID rồi âm thầm chạy test ad ngoài production
- `AdError` giờ là `public` + conform `LocalizedError` — app catch/phân biệt được từng loại lỗi; thêm case `noViewControllerToPresent`
- 4 class Preload dùng chung `PreloadCallbackStore` (thread-safe, có lock) thay vì mỗi class tự giữ 4-6 dictionary không lock; public API giữ nguyên
- `BannerContentView` đo width thật của container (GeometryReader) thay vì `UIScreen.main.bounds` — banner đúng size khi xoay màn hình / iPad split view, tự request lại ad theo size mới
- Log toàn package gom về `AdsLog` (chỉ in ở DEBUG) — `NativeAdViewModel` không còn `print` trong release build
- GA4 revenue event dùng `adValue.currencyCode` thật thay vì hardcode USD

### Fixed
- **Mất tracking doanh thu** khi view model bị release trước khi paid event đến: `paidEventHandler` giờ capture `adUnitID` theo value thay vì `[weak self]` (Interstitial/AppOpen/Rewarded/RewardedInterstitial/Native/NativeFullScreen)
- Các fullscreen view model reset `state` + nil ad object sau dismiss/fail-to-present — ad GMA chỉ present được 1 lần, instance tái dùng sẽ không bị kẹt ở trạng thái `.showing`
- `NativeFullScreenAdViewModel` báo sai `AdError.noInternet` khi không tìm được VC để present — giờ là `.noViewControllerToPresent`
- Revenue tracking system với delegate pattern
- Native ad color customization với `NativeAdColorConfig`
- `copyWith` method cho `NativeAdColorConfig`
- Support cho multiple ad types

### Changed
- Cải thiện error handling
- Tối ưu hóa performance
- Cập nhật Google Mobile Ads SDK lên version 12.8.0+

## [1.0.0] - 2025-01-13

### Added
- **App Open Ads**: Quảng cáo khi mở ứng dụng
- **Interstitial Ads**: Quảng cáo toàn màn hình
- **Rewarded Ads**: Quảng cáo có thưởng
- **Rewarded Interstitial Ads**: Quảng cáo toàn màn hình có thưởng
- **Banner Ads**: Quảng cáo banner
- **Native Ads**: Quảng cáo gốc với tùy chỉnh giao diện
- **Smart Ad Management**: Quản lý thông minh với interval và lifecycle
- **Loading Views**: Giao diện loading khi ads đang tải
- **Animation Support**: Hỗ trợ Lottie animations
- **Error Handling**: Xử lý lỗi toàn diện

### Features
- **AdsManager**: Quản lý tập trung tất cả loại quảng cáo
- **App Lifecycle Management**: Tự động quản lý app lifecycle
- **Interval Control**: Kiểm soát thời gian hiển thị interstitial ads
- **Network Monitoring**: Tự động kiểm tra kết nối internet
- **Revenue Tracking**: Hệ thống theo dõi doanh thu quảng cáo

### Technical
- **SwiftUI Support**: Tích hợp hoàn toàn với SwiftUI
- **Async/Await**: Sử dụng modern Swift concurrency
- **Memory Management**: Quản lý memory an toàn với weak references
- **Type Safety**: Đảm bảo type safety với strong typing
- **Modular Architecture**: Kiến trúc module hóa, dễ mở rộng

## [0.9.0] - 2025-01-10

### Added
- Initial project setup
- Basic ad integration structure
- Core ad models và view models

### Changed
- Project structure optimization
- Code organization improvements

## [0.8.0] - 2025-01-08

### Added
- Project initialization
- Basic Swift package structure
- Dependencies setup

---

## Cách đọc Changelog

- **[Unreleased]**: Những thay đổi chưa được release
- **[Version]**: Những thay đổi trong version cụ thể
- **Added**: Tính năng mới
- **Changed**: Thay đổi trong tính năng hiện có
- **Deprecated**: Tính năng sắp bị loại bỏ
- **Removed**: Tính năng đã bị loại bỏ
- **Fixed**: Sửa lỗi
- **Security**: Cập nhật bảo mật

## Ghi chú

- Tất cả dates đều theo format YYYY-MM-DD
- Version numbers theo [Semantic Versioning](https://semver.org/)
- Breaking changes sẽ được đánh dấu rõ ràng
