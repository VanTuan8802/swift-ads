//
//  CustomAppOpenAdManager.swift
//  AdmobSwitUI
//
//  Created by VanTuan8802 on 13/8/26.
//

import Foundation
import swift_ads
import UIKit

class CustomAppOpenAdManager {

    static let shared = CustomAppOpenAdManager()
    private var showCount = 0
    private var shouldShow = true
    private var isExcludeScreen = false

    func initialize() {
        listenToAppStateChanges()
    }

    func setShouldShow(_ value: Bool) {
        shouldShow = value
    }

    func setIsExcludeScreen(_ value: Bool) {
        isExcludeScreen = value
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func listenToAppStateChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppStateChange),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func handleAppStateChange() {
        guard shouldShow,
              !isExcludeScreen,
              !AdsManager.shared.isFullscreenAdShowing else {
            return
        }

        if (isExcludeScreen) {
            isExcludeScreen = false
            return
        }

        showCount += 1
        print("🔄 Custom Manager: App became active (count: \(showCount))")
    }
}
