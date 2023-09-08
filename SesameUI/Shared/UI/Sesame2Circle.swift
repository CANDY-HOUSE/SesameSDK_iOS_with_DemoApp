//
//  SesameCircle.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/13.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import UIKit

class ShakeCircle: UIControl {

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func startShake() {
        guard self.layer.animation(forKey: "shake") == nil else {
            return
        }
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 20
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 3, y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 3, y: self.center.y))

        self.layer.add(animation, forKey: "shake")
    }
    
    func stopShake() {
        self.layer.removeAnimation(forKey: "shake")
    }
}

class Sesame2Circle: ShakeCircle {/// Sesame 及 SesameBike 的按鈕
    private let renderer = Sesame2CircleKnobRenderer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        renderer.updateBounds(bounds)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        renderer.updateBounds(bounds)
    }

    func refreshUI(newPointerAngle: CGFloat, lockColor: UIColor) {
        layer.addSublayer(renderer.unlockImgLyer)
        renderer.updateunLockImage(newPointerAngle: newPointerAngle, lockColor: lockColor)
    }

    func removeDot() {
        renderer.unlockImgLyer.removeFromSuperlayer()
    }
}

private class Sesame2CircleKnobRenderer {
    
    let unlockImgLyer = CAShapeLayer()

    init() {
        unlockImgLyer.fillColor = UIColor.lockGray.cgColor
    }
    
    fileprivate func updateBounds(_ bounds: CGRect) {
        updateTrackLayerPath(bounds)
    }
    
    fileprivate func updateTrackLayerPath(_ bounds: CGRect) {
        
        let imageWidth = bounds.width / 2
        unlockImgLyer.frame = CGRect(x:0,y:0,width:bounds.width,height:bounds.width)
        let bounds = unlockImgLyer.bounds
        let radious = imageWidth/10
        let center = CGPoint(x: bounds.maxX - 1.0, y: bounds.midY)
        let ring = UIBezierPath(arcCenter: center,
                                radius: radious,
                                startAngle: 0,
                                endAngle: CGFloat(Double.pi) * 2,
                                clockwise: true)
        
        unlockImgLyer.path = ring.cgPath
    }
    
    fileprivate func updateunLockImage(newPointerAngle: CGFloat, lockColor: UIColor) {
        let to = CGFloat(Double.pi*2) / CGFloat(360) * newPointerAngle
        let translation = CGAffineTransform(rotationAngle: to)
        unlockImgLyer.setAffineTransform(translation)
        unlockImgLyer.fillColor = lockColor.cgColor
    }
}
