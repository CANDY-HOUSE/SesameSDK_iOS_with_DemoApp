//
//  BallClipRotatePulseAnimation.swift
//  SDK
//
//  Created by JING on 2020/11/24.
//  Copyright © 2020 Swift. All rights reserved.
//

import UIKit

class BallClipRotatePulseAnimation: BaseAnimation {
    override func setupAnimation(layer: CALayer, contentColor: UIColor, contentSize: CGSize) {
        let duration = 1.0
        
        let timingFunction = CAMediaTimingFunction.init(controlPoints: 0.09, 0.57, 0.49, 0.9);
        
        // Small circle
        do {
            let scaleAnimation = self.createKeyframeAnimation(keyPath: "transform.scale")
            
            scaleAnimation.keyTimes = [0.0, 0.3, 1.0]
            scaleAnimation.values = [NSValue.init(caTransform3D: CATransform3DMakeScale(1, 1, 1)), NSValue.init(caTransform3D: CATransform3DMakeScale(0.3, 0.3, 1)), NSValue.init(caTransform3D: CATransform3DMakeScale(1, 1, 1))]
            scaleAnimation.duration = duration
            scaleAnimation.repeatCount = HUGE
            scaleAnimation.timingFunctions = [timingFunction, timingFunction]
            
            let circleSize = contentSize.width / 2
            let circle = CALayer.init()
            
            circle.frame = .init(x: (layer.bounds.size.width - circleSize) / 2, y: (layer.bounds.size.height - circleSize) / 2, width: circleSize, height: circleSize)
            circle.backgroundColor = contentColor.cgColor
            circle.cornerRadius = circleSize / 2
            circle.add(scaleAnimation, forKey: "animation")
            layer.addSublayer(circle)
        }
        
        // Big circle
        do {
            // Scale animation
            let scaleAnimation = self.createKeyframeAnimation(keyPath: "transform.scale")
            scaleAnimation.keyTimes = [0.0, 0.5, 1.0]
            
            
            
            scaleAnimation.values = [[NSValue.init(caTransform3D: CATransform3DMakeScale(1, 1, 1)), NSValue.init(caTransform3D: CATransform3DMakeScale(0.6, 0.6, 1)), NSValue.init(caTransform3D: CATransform3DMakeScale(1, 1, 1))]]
            scaleAnimation.duration = duration
            scaleAnimation.timingFunctions = [timingFunction, timingFunction]
            
            // Rotate animation
            let rotateAnimation = self.createKeyframeAnimation(keyPath: "transform.rotation.z")
            
            rotateAnimation.values = [0, M_PI, 2 * M_PI]
            rotateAnimation.keyTimes = scaleAnimation.keyTimes
            rotateAnimation.duration = duration
            rotateAnimation.timingFunctions = [timingFunction, timingFunction]
            
            // Animation
            let animation = self.createAnimationGroup()
            
            animation.animations = [scaleAnimation, rotateAnimation]
            animation.duration = duration
            animation.repeatCount = HUGE
            
            // Draw big circle
            let circleSize = contentSize.width
            let circle = CAShapeLayer.init()
            let circlePath = UIBezierPath.init()
            
            let a = Double(circleSize) / 2.0 * M_PI / 4.0
            let x = Double(circleSize) / 2.0 - a
            let y = Double(circleSize) / 2.0 + a
            
            
            circlePath.addArc(withCenter: .init(x: circleSize / 2.0, y: circleSize / 2.0), radius: circleSize / 2.0, startAngle: CGFloat(-3 * M_PI / 4.0), endAngle: CGFloat(-M_PI / 4.0), clockwise: true)
            circlePath.move(to: .init( x: x, y: y))

            circlePath.addArc(withCenter: .init(x: circleSize / 2.0, y: circleSize / 2.0), radius: circleSize / 2.0, startAngle: CGFloat(-5 * M_PI / 4.0), endAngle: -7, clockwise: false)
            
            circle.path = circlePath.cgPath
            circle.lineWidth = 2
            circle.fillColor = nil
            circle.strokeColor = contentColor.cgColor
            
            circle.frame = .init(x: (layer.bounds.size.width - circleSize) / 2, y: (layer.bounds.size.height - circleSize) / 2, width: circleSize, height: circleSize)
            circle.add(animation, forKey: "animation")
            layer.addSublayer(circle)
        }
        
    }
    
}
