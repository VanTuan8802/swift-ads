//
//  BannerContentView.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import GoogleMobileAds
import SwiftUI

public struct BannerContentView: View {
    private let adUnitID: String
    @StateObject private var viewModel = BannerAdViewModel()
    // Đo width thật của container (thay vì UIScreen.main.bounds) để banner
    // đúng kích thước khi xoay màn hình / iPad split view.
    @State private var containerWidth: CGFloat = UIScreen.main.bounds.size.width

    public init(adUnitID: String) {
        self.adUnitID = adUnitID
    }

    public var body: some View {
        let adSize = currentOrientationAnchoredAdaptiveBanner(width: containerWidth)
        let bannerHeight = adSize.size.height
        let shouldShow = viewModel.adLoaded || viewModel.isLoading

        ZStack {
            // Luôn giữ trong hierarchy để makeUIView chạy và ad.load() được gọi
            BannerViewContainer(adSize, adUnitID: adUnitID, viewModel: viewModel)
                .frame(width: adSize.size.width, height: bannerHeight)
                .opacity(viewModel.adLoaded ? 1 : 0)

            if viewModel.isLoading {
                ShimmerBannerLoadingView(height: bannerHeight)
                    .frame(width: adSize.size.width, height: bannerHeight)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: shouldShow ? bannerHeight : 0)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        if geo.size.width > 0 { containerWidth = geo.size.width }
                    }
                    .onChange(of: geo.size.width) { newWidth in
                        if newWidth > 0 { containerWidth = newWidth }
                    }
            }
        )
        .clipped()
    }
}

struct BannerContentView_Previews: PreviewProvider {
    static var previews: some View {
        BannerContentView(adUnitID: "ca-app-pub-3940256099942544/2435281174")
    }
}

private struct BannerViewContainer: UIViewRepresentable {
    typealias UIViewType = BannerView
    let adSize: AdSize
    let adUnitID: String
    let viewModel: BannerAdViewModel

    init(_ adSize: AdSize, adUnitID: String, viewModel: BannerAdViewModel) {
        self.adSize = adSize
        self.adUnitID = adUnitID
        self.viewModel = viewModel
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.delegate = viewModel
        banner.rootViewController = UIApplication.getTopViewController()
        banner.paidEventHandler = { [adUnitID] adValue in
            AdRevenueTracker.shared.trackAdRevenue(adValue: adValue,
                                                   adUnit: adUnitID,
                                                   adType: .banner)
        }
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        // Chỉ cập nhật khi width thực sự đổi (xoay màn hình) — GMA tự request
        // ad mới theo size mới. Guard tránh vòng lặp update như vụ rootViewController cũ.
        guard uiView.adSize.size.width != adSize.size.width else { return }
        uiView.adSize = adSize
    }
}
