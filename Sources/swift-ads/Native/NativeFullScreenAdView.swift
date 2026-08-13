//
//  NativeFullScreenAdView.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import GoogleMobileAds
import SwiftUI

/// UIViewRepresentable that renders a NativeAd in a full-screen layout.
/// All colors are taken from NativeAdColorConfig (via AdsManager.shared.getNativeAdColorConfig()).
///
/// Layout matching screenshot:
/// - Black background, media fills upper area
/// - Bottom white panel pinned to bottom:
///   - Row: icon (left) + headline (right)
///   - Body text below
///   - Full-width CTA button at very bottom
struct NativeFullScreenAdView: UIViewRepresentable {
    typealias UIViewType = NativeAdView

    @ObservedObject var nativeViewModel: NativeAdViewModel
    var colorConfig: NativeAdColorConfig?

    private static let bottomContainerTag = 101
    private static let separatorTag = 102

    func makeUIView(context: Context) -> NativeAdView {
        let config = self.colorConfig ?? AdsManager.shared.getNativeAdColorConfig()

        let nativeAdView = NativeAdView()
        nativeAdView.backgroundColor = UIColor(config.backgroundColor)

        // === Media View (fills upper area) ===
        let mediaView = MediaView()
        mediaView.contentMode = .scaleAspectFit
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(mediaView)
        nativeAdView.mediaView = mediaView

        // === Bottom Container (transparent, pinned to bottom) ===
        let bottomContainer = UIView()
        bottomContainer.tag = NativeFullScreenAdView.bottomContainerTag
        bottomContainer.backgroundColor = .clear // Matches nativeAdView background
        bottomContainer.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(bottomContainer)

        // === Icon ===
        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = 8
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(iconImageView)
        nativeAdView.iconView = iconImageView

        // === Headline ===
        let headlineLabel = UILabel()
        headlineLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold) // Adjusted font
        headlineLabel.textColor = UIColor(config.headlineColor)
        headlineLabel.numberOfLines = 2
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(headlineLabel)
        nativeAdView.headlineView = headlineLabel

        // === Body ===
        let bodyLabel = UILabel()
        bodyLabel.font = UIFont.systemFont(ofSize: 15) // Adjusted font
        bodyLabel.textColor = UIColor(config.bodyColor)
        bodyLabel.numberOfLines = 3
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(bodyLabel)
        nativeAdView.bodyView = bodyLabel

        // === CTA Button ===
        let ctaButton = UIButton(type: .system)
        ctaButton.backgroundColor = UIColor(config.callToActionBackgroundColor)
        ctaButton.setTitleColor(UIColor(config.callToActionTextColor), for: .normal)
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        ctaButton.layer.cornerRadius = 16
        ctaButton.clipsToBounds = true
        ctaButton.isUserInteractionEnabled = false
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        bottomContainer.addSubview(ctaButton)
        nativeAdView.callToActionView = ctaButton

        // === Ad Label ===
        let adLabel = UILabel()
        adLabel.text = "Ad"
        adLabel.tag = 9
        adLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        adLabel.textColor = UIColor(config.adColor)
        adLabel.backgroundColor = UIColor(config.adBackgroundColor)
        adLabel.textAlignment = .center
        adLabel.layer.cornerRadius = 4
        adLabel.clipsToBounds = true
        adLabel.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.addSubview(adLabel)

        // === Layout Constraints ===
        NSLayoutConstraint.activate([
            // Bottom container spans full width and anchors to bottom
            bottomContainer.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor),
            bottomContainer.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor),

            // Media fills remaining top space
            mediaView.topAnchor.constraint(equalTo: nativeAdView.safeAreaLayoutGuide.topAnchor),
            mediaView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor),
            mediaView.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor),

            // Icon: top-left of bottom container
            iconImageView.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 20),
            iconImageView.topAnchor.constraint(equalTo: bottomContainer.topAnchor, constant: 16),
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48),

            // Headline: to the right of icon, vertically centered with icon
            headlineLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            headlineLabel.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -20),
            headlineLabel.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),

            // Body: well spaced below icon
            bodyLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            bodyLabel.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 20),
            bodyLabel.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -20),

            // CTA button: spaced out, full width, avoids safe area bottom
            ctaButton.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 24),
            ctaButton.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 20),
            ctaButton.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -20),
            ctaButton.heightAnchor.constraint(equalToConstant: 48),
            ctaButton.bottomAnchor.constraint(equalTo: nativeAdView.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            // Ad label: safely anchored top-left
            adLabel.leadingAnchor.constraint(equalTo: nativeAdView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            adLabel.topAnchor.constraint(equalTo: nativeAdView.safeAreaLayoutGuide.topAnchor, constant: 16),
            adLabel.widthAnchor.constraint(equalToConstant: 24),
            adLabel.heightAnchor.constraint(equalToConstant: 18),
        ])

        return nativeAdView
    }

    func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        guard let nativeAd = nativeViewModel.nativeAd else { return }

        // Bind ad data
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        nativeAdView.callToActionView?.isUserInteractionEnabled = false

        // Apply ALL colors from config
        let config = self.colorConfig ?? AdsManager.shared.getNativeAdColorConfig()

        // Main background
        nativeAdView.backgroundColor = UIColor(config.backgroundColor)

        // Ad label
        if let adLabel = nativeAdView.viewWithTag(9) as? UILabel {
            adLabel.textColor = UIColor(config.adColor)
            adLabel.backgroundColor = UIColor(config.adBackgroundColor)
        }

        // Headline & Body
        (nativeAdView.headlineView as? UILabel)?.textColor = UIColor(config.headlineColor)
        (nativeAdView.bodyView as? UILabel)?.textColor = UIColor(config.bodyColor)

        // CTA Button
        if let ctaButton = nativeAdView.callToActionView as? UIButton {
            ctaButton.backgroundColor = UIColor(config.callToActionBackgroundColor)
            ctaButton.setTitleColor(UIColor(config.callToActionTextColor), for: .normal)
        }

        nativeAdView.nativeAd = nativeAd
    }
}
