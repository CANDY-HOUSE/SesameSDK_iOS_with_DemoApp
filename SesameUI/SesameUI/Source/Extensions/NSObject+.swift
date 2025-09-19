//
//  NSObject+.swift
//  SesameUI
//
//  Created by eddy on 2024/4/19.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

public extension NSObject {
    
    private struct AssociatedKeys {
        static var feedbackGenerator: UIImpactFeedbackGenerator?
    }
    
    private var feedbackGenerator: UIImpactFeedbackGenerator? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.feedbackGenerator) as? UIImpactFeedbackGenerator
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.feedbackGenerator, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func prepareHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .heavy) {
        feedbackGenerator = UIImpactFeedbackGenerator(style: style)
        feedbackGenerator?.prepare()
    }
    
    func triggerHapticFeedback() {
        feedbackGenerator?.impactOccurred()
    }
}

struct DevicePreference {
    var isExpandable = false
    var expanded = false
    public private(set) var selectExpandIndex = -1
    
    init(isExpandable: Bool = false, expanded: Bool = false, selectIndex: Int = 1) {
        self.isExpandable = isExpandable
        self.expanded = expanded
        self.selectExpandIndex = selectIndex
    }
    
    mutating func updateSelectExpandIndex(_ index: Int) {
        selectExpandIndex = index
    }
}

private var associatedObjectKey: UInt8 = 0
extension CHDevice {
    var preference: DevicePreference {
        get {
            return (objc_getAssociatedObject(self, &associatedObjectKey) as? DevicePreference) ?? DevicePreference(isExpandable: false, expanded: false)
        }
        set {
            objc_setAssociatedObject(self, &associatedObjectKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
