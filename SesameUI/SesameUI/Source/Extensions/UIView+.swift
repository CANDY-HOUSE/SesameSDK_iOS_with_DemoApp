//
//  NSObject+.swift
//  SesameUI
//
//  Created by eddy on 2024/1/5.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func setSeperatorLineEnable(_ yeOrNo: Bool = true, trailingConstant: CGFloat = 0) {
        let lineView = CHUIViewGenerator.seperatorWithStyle(.thin)
        addSubview(lineView)
        lineView.autoPinLeading()
        lineView.autoPinTrailing(constant: trailingConstant)
        lineView.autoPinBottom()
        lineView.autoLayoutHeight(1)
        lineView.isHidden = !yeOrNo
    }
}

private struct AssociatedKeys {
    static let copyHandler = UnsafeRawPointer(bitPattern: "copyHandler".hashValue)!
    static let temporaryCopyHandler = UnsafeRawPointer(bitPattern: "temporaryCopyHandler".hashValue)!
}

extension UIView {

    var copyHandler: (() -> String?)? {
        get {
            return objc_getAssociatedObject(self, AssociatedKeys.copyHandler) as? (() -> String?)
        }
        set {
            objc_setAssociatedObject(self, AssociatedKeys.copyHandler, newValue, .OBJC_ASSOCIATION_COPY)
            if newValue != nil {
                enableCopyFunctionality()
            } else {
                disableCopyFunctionality()
            }
        }
    }
    
    private func enableCopyFunctionality() {
        isUserInteractionEnabled = true
        if gestureRecognizers?.contains(where: { $0 is UITapGestureRecognizer }) != true {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            addGestureRecognizer(tapGesture)
        }
    }
    
    private func disableCopyFunctionality() {
        gestureRecognizers?.forEach { gesture in
            if gesture is UITapGestureRecognizer {
                removeGestureRecognizer(gesture)
            }
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        showCopyMenu()
    }
    
    private func showCopyMenu() {
        guard copyHandler != nil else { return }
        presentCopyMenu()
    }
    
    func showCopyMenu(copyHandler: @escaping () -> String?) {
        objc_setAssociatedObject(self, AssociatedKeys.temporaryCopyHandler, copyHandler, .OBJC_ASSOCIATION_COPY)
        presentCopyMenu()
    }
    
    private func presentCopyMenu() {
        becomeFirstResponder()
        let menu = UIMenuController.shared
        if #available(iOS 13.0, *) {
            menu.showMenu(from: self, rect: bounds)
        } else {
            menu.setTargetRect(bounds, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }
    
    override open var canBecomeFirstResponder: Bool {
        return copyHandler != nil || objc_getAssociatedObject(self, AssociatedKeys.temporaryCopyHandler) != nil
    }
    
    @objc override open func copy(_ sender: Any?) {
        let handler = objc_getAssociatedObject(self, AssociatedKeys.temporaryCopyHandler) as? () -> String? ?? copyHandler
        if let stringToCopy = handler?() {
            UIPasteboard.general.string = stringToCopy
        }
    }
}

