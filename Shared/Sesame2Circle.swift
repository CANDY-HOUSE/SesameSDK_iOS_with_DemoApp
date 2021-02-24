//
//  SesameCircle.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/13.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import UIKit

class ShakeCircle: UIControl {
    
    var shapeLayer: CAShapeLayer?
    fileprivate var animationTimer: Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func trackLayer(frame: CGRect) -> CAShapeLayer {
        let trackLayer = CAShapeLayer()
        trackLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        trackLayer.lineCap = CAShapeLayerLineCap.round
        trackLayer.lineWidth = 1.2
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.lockGray.cgColor //UIColor(hexString: "#E4E3E3").cgColor
        trackLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        trackLayer.path = UIBezierPath(arcCenter: .zero, radius: (frame.width / 2)-1, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true).cgPath
        return trackLayer
    }
    
    func shapeLayer(frame: CGRect) -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.position = CGPoint(x: frame.width / 2, y: frame.height / 2)
        shapeLayer.lineCap = CAShapeLayerLineCap.round
        shapeLayer.lineWidth = 2
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.sesame2Green.cgColor//UIColor(red: 80 / 255, green: 80 / 255, blue: 80 / 255, alpha: 0.5).cgColor
        shapeLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        shapeLayer.path = UIBezierPath(arcCenter: .zero, radius: frame.width / 2, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: true).cgPath
        shapeLayer.transform = CATransform3DMakeRotation(-CGFloat.pi / 2, 0, 0, 1)
        shapeLayer.strokeEnd = 0.0

        return shapeLayer
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

class Sesame2Circle: UIControl {
    
    private let renderer = Sesame2CircleKnobRenderer()
    private var pointerAngle: CGFloat = 0.0

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
    
    func refreshUI(newPointerAngle: CGFloat, lockColor: UIColor) {
        pointerAngle = newPointerAngle
        renderer.updateunLockImage(newPointerAngle: newPointerAngle, lockColor: lockColor)
    }
    
    func refreshUI(lockColor: UIColor) {
        renderer.updateunLockImage(newPointerAngle: pointerAngle, lockColor: lockColor)
    }
}

private class Sesame2CircleKnobRenderer {
    
    let unlockImgLyer = CAShapeLayer()
    var bounds = CGRect.zero
    var imageWidth: CGFloat = 0.0
    
    init() {
        unlockImgLyer.fillColor = UIColor.lockGray.cgColor
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
