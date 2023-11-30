//
//  UIView+AutoLayout.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/15.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

extension UIView {
    
    @discardableResult
    func autoPinEdgesToSuperview(safeArea: Bool = true) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        
        let topAnchorConstraint: NSLayoutConstraint
        let bottomAnchorConstraint: NSLayoutConstraint
        let leadingAnchorConstraint: NSLayoutConstraint
        let trailingAnchorConstraint: NSLayoutConstraint
        
        if safeArea {
            topAnchorConstraint = topAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.topAnchor)
            bottomAnchorConstraint = bottomAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.bottomAnchor)
        } else {
            topAnchorConstraint = topAnchor.constraint(equalTo: self.superview!.topAnchor)
            bottomAnchorConstraint = bottomAnchor.constraint(equalTo: self.superview!.bottomAnchor)
        }
        
        leadingAnchorConstraint = leadingAnchor.constraint(equalTo: self.superview!.leadingAnchor)
        trailingAnchorConstraint = trailingAnchor.constraint(equalTo: self.superview!.trailingAnchor)
        
        topAnchorConstraint.isActive = true
        bottomAnchorConstraint.isActive = true
        leadingAnchorConstraint.isActive = true
        trailingAnchorConstraint.isActive = true
        
        return [
            topAnchorConstraint,
            bottomAnchorConstraint,
            leadingAnchorConstraint,
            bottomAnchorConstraint
        ]
    }
    
    @discardableResult
    func autoLayoutHeight(_ height: CGFloat) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let heightConstraint = heightAnchor.constraint(equalToConstant: height)
        heightConstraint.isActive = true
        return heightConstraint
    }
    
    @discardableResult
    func autoLayoutWidth(_ width: CGFloat) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = widthAnchor.constraint(equalToConstant: width)
        widthConstraint.isActive = true
        return widthConstraint
    }
    
    @discardableResult
    func autoPinWidth(constant: CGFloat = 0) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = widthAnchor.constraint(equalTo: superview!.widthAnchor, multiplier: 1.0, constant: constant)
        widthConstraint.isActive = true
        return widthConstraint
    }
    
    @discardableResult
    func autoEqualWidthTo(_ view: UIView) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = widthAnchor.constraint(equalTo: view.widthAnchor)
        widthConstraint.isActive = true
        return widthConstraint
    }
    
    @discardableResult
    func autoPinWidthLessThanOrEqual(_ view: UIView) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor)
        widthConstraint.isActive = true
        return widthConstraint
    }
    
    @discardableResult
    func autoPinCenterX() -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let centerXAnchor = self.centerXAnchor.constraint(equalTo: self.superview!.centerXAnchor)
        centerXAnchor.isActive = true
        return centerXAnchor
    }
    
    @discardableResult
    func autoPinCenterY(constant: CGFloat = 0) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let centerYAnchor = self.centerYAnchor.constraint(equalTo: self.superview!.centerYAnchor, constant: constant)
        centerYAnchor.isActive = true
        return centerYAnchor
    }
    
    @discardableResult
    func autoPinCenter() -> [NSLayoutConstraint] {
        [autoPinCenterX(), autoPinCenterY()]
    }
    
    @discardableResult
    func autoPinBottomToSafeArea(_ toSafeArea: Bool = true, constant: CGFloat = 0) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let bottomAnchor: NSLayoutConstraint
        if toSafeArea {
            bottomAnchor = self.bottomAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.bottomAnchor, constant: constant)
        } else {
           bottomAnchor = self.bottomAnchor.constraint(equalTo: self.superview!.bottomAnchor, constant: constant)
        }
        bottomAnchor.isActive = true
        return bottomAnchor
    }
    
    @discardableResult
    func autoPinTopToSafeArea(_ toSafeArea: Bool = true, constant: CGFloat = 0) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let topAnchor: NSLayoutConstraint
        if toSafeArea {
            topAnchor = self.topAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.topAnchor, constant: constant)
        } else {
           topAnchor = self.topAnchor.constraint(equalTo: self.superview!.topAnchor, constant: constant)
        }
        topAnchor.isActive = true
        return topAnchor
    }
    
    @discardableResult
    func autoPinRight(constant: CGFloat = 0) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let rightAnchor = self.rightAnchor.constraint(equalTo: superview!.rightAnchor, constant: constant)
        rightAnchor.isActive = true
        return rightAnchor
    }
    
    @discardableResult
    func autoPinBottom(constant: CGFloat = 0) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let bottomAnchor = self.bottomAnchor.constraint(equalTo: superview!.bottomAnchor, constant: constant)
        bottomAnchor.isActive = true
        return bottomAnchor
    }
    
    @discardableResult
    func autoPinTop(constant: CGFloat = 0) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let topAnchor = self.topAnchor.constraint(equalTo: superview!.topAnchor, constant: constant)
        topAnchor.isActive = true
        return topAnchor
    }
    
    @discardableResult
    func autoPinLeading(constant: CGFloat = 0) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let leadingAnchor = self.leadingAnchor.constraint(equalTo: superview!.leadingAnchor, constant: constant)
        leadingAnchor.isActive = true
        return leadingAnchor
    }
    
    @discardableResult
    func autoPinTrailing(constant: CGFloat = 0) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let trailingAnchor = self.trailingAnchor.constraint(equalTo: superview!.trailingAnchor, constant: constant)
        trailingAnchor.isActive = true
        return trailingAnchor
    }
    
    @discardableResult
    func autoPinTopToBottomOfView(_ view: UIView, constant: CGFloat = 0) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let topToBottom = topAnchor.constraint(equalTo: view.bottomAnchor, constant: constant)
        topToBottom.isActive = true
        return topToBottom
    }
    
    @discardableResult
    func autoPinTrailingToLeadingOfView(_ view: UIView, constant: CGFloat = 0) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let trailingToLeading = trailingAnchor.constraint(equalTo: view.leadingAnchor, constant: constant)
        trailingToLeading.isActive = true
        return trailingToLeading
    }
    
    @discardableResult
    func autoPinLeadingToTrailingOfView(_ view: UIView, constant: CGFloat = 0) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let leadingToTrailing = leadingAnchor.constraint(equalTo: view.trailingAnchor, constant: constant)
        leadingToTrailing.isActive = true
        return leadingToTrailing
    }
    
    static func autoLayoutStackView(_ stackView: UIStackView, inScrollView scrollView: UIScrollView) {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.autoPinEdgesToSuperview(safeArea: false)
        stackView.autoPinEdgesToSuperview(safeArea: false)
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
    }
}
