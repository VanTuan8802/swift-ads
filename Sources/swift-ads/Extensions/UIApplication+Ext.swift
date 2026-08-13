//
//  UIApplication+Ext.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import Foundation
import UIKit

extension UIApplication {
    public static var firstWindow: UIWindow? {
        shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first { $0.isKeyWindow }
    }

    public static func getTopViewController() -> UIViewController? {
        firstWindow?.rootViewController?.topmostPresentedViewController
    }
}

extension UIViewController {
    /// Walk the presentedViewController chain to find the topmost *user-visible* VC.
    ///
    /// Only traverses into VCs that are:
    /// - Not currently being dismissed (`!isBeingDismissed`)
    /// - Actually in the window hierarchy (`view.window != nil`)
    ///
    /// This prevents going into internal SwiftUI hosting VCs that are not real
    /// user-facing modals, which would cause App Open Ad to fail silently and freeze.
    var topmostPresentedViewController: UIViewController {
        var top = self
        while let presented = top.presentedViewController,
              !presented.isBeingDismissed,
              presented.view.window != nil {
            top = presented
        }
        return top
    }
}
