//
//  BaseAnimation.swift
//  SDK
//
//  Created by DJ on 2020/5/28.
//  Copyright © 2020 Swift. All rights reserved.
//

import UIKit

 @objc protocol AnimationProtocol {
    func setupAnimation(layer: CALayer, contentColor: UIColor, contentSize: CGSize)
}

class BaseAnimation: NSObject, AnimationProtocol {
    
    func createBasicAnimation(keyPath: String) -> CABasicAnimation {
        let animation = CABasicAnimation.init(keyPath: keyPath)
        animation.isRemovedOnCompletion = false
        return animation
    }
    
    func createKeyframeAnimation(keyPath: String) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation.init(keyPath: keyPath)
        animation.isRemovedOnCompletion = false
        return animation
    }

    func createAnimationGroup() -> CAAnimationGroup {
        let animation = CAAnimationGroup.init()
        animation.isRemovedOnCompletion = false
        return animation
    }
    
    func setupAnimation(layer: CALayer, contentColor: UIColor, contentSize: CGSize) {
        
    }
    
}
