//
//  AdLoadingVC.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import UIKit
import GoogleMobileAds
import Lottie

class AdLoadingVC: UIViewController {
    private var animationView: LottieAnimationView?

    private var setTimer: Timer?
    private var isViewVisible = false
    private var isDismissing = false
    private var isPresented = false
    private var pendingDismiss = false

    var blockDidDismiss: (() -> Void)?

    private let animationFiles = AdsManager.shared.animationFiles ?? [
        "waiting1", "waiting2", "waiting3", "waiting4", "waiting5",
        "waiting6", "waiting7", "waiting8", "waiting9", "waiting10",
        "waiting11", "waiting12", "waiting13"
    ]

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func createViewController() -> AdLoadingVC {
        return AdLoadingVC()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !isPresented else { return }
        isPresented = true
        isViewVisible = true
        startLoading()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Ad finished loading before the loading view became visible — dismiss now.
        if pendingDismiss {
            pendingDismiss = false
            dismissLoading()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isViewVisible = false
        stopLoading()
    }

    private func setupUI() {
        view.backgroundColor = .white

        let randomAnimation = getRandomAnimation()
        setupAnimationView(with: randomAnimation)
    }
    
    private func getRandomAnimation() -> String {
        let randomIndex = Int.random(in: 0..<animationFiles.count)
        return animationFiles[randomIndex]
    }
    
    private func setupAnimationView(with animationName: String) {
        animationView?.removeFromSuperview()
        if let animation = LottieAnimation.named(animationName, bundle: Bundle.module) {
            animationView = LottieAnimationView(animation: animation)
        } else {
            animationView = LottieAnimationView(name: animationName)
        }

        animationView?.contentMode = .scaleAspectFit
        animationView?.loopMode = .loop
        animationView?.translatesAutoresizingMaskIntoConstraints = false

        if let animationView = animationView {
            view.addSubview(animationView)
            NSLayoutConstraint.activate([
                animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                animationView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
                animationView.heightAnchor.constraint(equalTo: animationView.widthAnchor)
            ])
        }
    }

    private func startLoading() {
        guard isViewVisible, !isDismissing else { return }

        DispatchQueue.main.async { [weak self] in
            self?.animationView?.play()
        }
    }

    private func stopLoading() {
        DispatchQueue.main.async { [weak self] in
            self?.animationView?.stop()
        }
    }

    func dismissLoading() {
        guard !isDismissing else { return }
        // If the view hasn't appeared yet, defer the dismiss until viewDidAppear
        // so the loading overlay can never get stuck on screen.
        guard isViewVisible else {
            pendingDismiss = true
            return
        }
        isDismissing = true

        DispatchQueue.main.async { [weak self] in
            self?.stopLoading()
            self?.dismiss(animated: false) { [weak self] in
                self?.blockDidDismiss?()
                self?.isDismissing = false
                self?.isPresented = false
            }
        }
    }
}
