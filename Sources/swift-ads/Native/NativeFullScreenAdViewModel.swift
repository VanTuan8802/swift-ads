//
//  NativeFullScreenAdViewModel.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import SwiftUI
import GoogleMobileAds
import Combine

/// ViewModel that loads a NativeAd and presents it in a full-screen popup
/// using NativeFullScreenContentView wrapped in UIHostingController.
/// All colors from AdsManager.shared.getNativeAdColorConfig().
class NativeFullScreenAdViewModel: @unchecked Sendable {

    // MARK: - Callbacks

    var onShowed: (() -> Void)?
    var onDismissed: (() -> Void)?
    var onFailed: ((Error) -> Void)?
    var onCloseButtonTapped: (() -> Void)?

    // MARK: - Config

    private let adUnitID: String
    private let showCloseButton: Bool

    // MARK: - State

    private var nativeAdViewModel: NativeAdViewModel?
    private var hostingVC: UIViewController?
    private var cancellables = Set<AnyCancellable>()

    init(adUnitID: String, showCloseButton: Bool = true) {
        self.adUnitID = adUnitID
        self.showCloseButton = showCloseButton
    }

    // MARK: - Show Ad

    @MainActor
    func showAd() {
        let viewModel = NativeAdViewModel(adUnitID: adUnitID)
        nativeAdViewModel = viewModel

        // Observe when ad loads via Combine
        viewModel.$nativeAd
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] nativeAd in
                if nativeAd != nil {
                    self?.presentFullScreen()
                }
            }
            .store(in: &cancellables)

        // Observe load failure so the caller's onFailed fires on no-fill (otherwise it hangs).
        viewModel.$isLoadFailed
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] failed in
                if failed {
                    self?.handleLoadFailed()
                }
            }
            .store(in: &cancellables)

        viewModel.refreshAd()
    }

    @MainActor
    private func handleLoadFailed() {
        let error = NSError(
            domain: "NativeFullScreenAd",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Native ad failed to load"]
        )
        onFailed?(error)
        cleanup()
    }

    // MARK: - Present

    @MainActor
    private func presentFullScreen() {
        guard let viewModel = nativeAdViewModel else { return }

        // Capture adUnitID theo value — paid event có thể đến sau khi
        // view model bị release, weak self sẽ làm mất tracking doanh thu.
        viewModel.nativeAd?.paidEventHandler = { [adUnitID] adValue in
            AdRevenueTracker.shared.trackAdRevenue(
                adValue: adValue,
                adUnit: adUnitID,
                adType: .nativeFullScreen
            )
        }

        let contentView = NativeFullScreenContentView(
            nativeViewModel: viewModel,
            showCloseButton: showCloseButton,
            onCloseButtonTapped: { [weak self] in
                self?.onCloseButtonTapped?()
                self?.dismiss()
            }
        )

        let hostingVC = UIHostingController(rootView: contentView)
        hostingVC.modalPresentationStyle = .fullScreen
        hostingVC.view.backgroundColor = UIColor(AdsManager.shared.getNativeAdColorConfig().backgroundColor)
        self.hostingVC = hostingVC

        guard let topVC = UIApplication.getTopViewController() else {
            onFailed?(AdError.noViewControllerToPresent)
            cleanup()
            return
        }

        topVC.present(hostingVC, animated: true) { [weak self] in
            self?.onShowed?()
        }
    }

    // MARK: - Dismiss

    @MainActor
    func dismiss() {
        hostingVC?.dismiss(animated: true) { [weak self] in
            self?.onDismissed?()
            self?.cleanup()
        }
    }

    // MARK: - Cleanup

    @MainActor
    private func cleanup() {
        cancellables.removeAll()
        nativeAdViewModel = nil
        hostingVC = nil
    }
}
