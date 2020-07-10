//
//  SesameCircle.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/13.
//  Copyright © 2019 Cerberus. All rights reserved.
//

#if os(iOS)
import UIKit

class SesameCircle: UIControl {
    
    private let renderer = KnobRenderer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        layer.addSublayer(renderer.unlockImgLyer)
        renderer.updateBounds(bounds)
    }
    
    public func refreshUI(newPointerAngle: CGFloat, lockColor: UIColor) {
        renderer.updateunLockImage(newPointerAngle: newPointerAngle, lockColor: lockColor)
    }
}


private class KnobRenderer {

    let unlockImgLyer = CAShapeLayer()
    var bounds = CGRect.zero
    var imageWidth: CGFloat = 0.0

    init() {
    }

    fileprivate func updateBounds(_ bounds: CGRect) {
        self.bounds = bounds
        updateTrackLayerPath()
    }
    
    fileprivate func updateTrackLayerPath() {

        imageWidth = bounds.width / 2

        unlockImgLyer.frame = CGRect(x: 0,
                                     y: 0,
                                     width: bounds.width,
                                     height: bounds.width)

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
        
        guard lockColor.cgColor != unlockImgLyer.fillColor else {
            return
        }
        let currentColor = unlockImgLyer.fillColor
        unlockImgLyer.fillColor = lockColor.cgColor
        
        let fillColorAnimation = CABasicAnimation(keyPath: "fillColor")
        fillColorAnimation.fromValue = currentColor
        fillColorAnimation.toValue = lockColor.cgColor
        fillColorAnimation.duration = 0.3
        fillColorAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        fillColorAnimation.autoreverses = false
        fillColorAnimation.repeatCount = 0
        unlockImgLyer.add(fillColorAnimation, forKey: "fillColorAnimation")
    }
}
#endif
