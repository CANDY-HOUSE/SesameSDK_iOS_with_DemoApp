//
//  SesameView.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/10/11.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import Foundation

import UIKit.UIGestureRecognizerSubclass
import SesameSDK

class SesameView: UIControl {
    
    var viewModel: SesameViewModel!

    private let renderer = KnobRenderer()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        L.d("init aDecoder")
        commonInit()
    }

    private func commonInit() {
        layer.addSublayer(renderer.centerBigLayer)
        layer.addSublayer(renderer.lockImgLyer)
        layer.addSublayer(renderer.unlockImgLyer)
        renderer.updateBounds(bounds)
    }

    public func refreshUI() {
        let lockPosition = viewModel.lockPositions()
        guard let currentDegree = viewModel.currentDegree(),
            let lockPositionDegree = lockPosition.lockPosition,
            let unlockPositionDegree = lockPosition.unlockPosition else {
                return
        }
        renderer.setPointerAngle(CGFloat(currentDegree))
        renderer.updateLockImg(CGFloat(lockPositionDegree))
        renderer.updateunLockImg(CGFloat(unlockPositionDegree))
    }
}

private class KnobRenderer {

    var lockPointerLength: CGFloat = 50

    let trackLayer = CAShapeLayer()
    let lockLayer = CAShapeLayer()
    let centerBigLayer = CALayer()
    let lockImgLyer = CALayer()
    let unlockImgLyer = CALayer()

    init() {
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor(rgb: 0x28aeb1).cgColor
        lockLayer.fillColor = UIColor.clear.cgColor
        lockLayer.strokeColor = UIColor(rgb: 0x28aeb1).cgColor
        trackLayer.lineWidth = 20
    }

    func updateBounds(_ bounds: CGRect) {

        trackLayer.bounds = bounds
        trackLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        lockLayer.bounds = bounds
        lockLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        centerBigLayer.bounds = bounds
        centerBigLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        lockImgLyer.bounds = bounds
        lockImgLyer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        unlockImgLyer.bounds = bounds
        unlockImgLyer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        updateTrackLayerPath()
        updatePointerLayerPath()
        updateCentLock()
    }

    func updateLockImg(_ newPointerAngle: CGFloat) {

        let qqqq = CGFloat(Double.pi*2)  / CGFloat(360) * newPointerAngle
        let bounds = lockLayer.bounds
        let myImage = UIImage.SVGImage(named: "icon_lock")?.cgImage

        let ss = sin(qqqq)
        let aa = cos(qqqq)

        let  imageW = bounds.width/10
        let  redius = bounds.width/2

        lockImgLyer.frame = CGRect(
            x: bounds.midX - imageW/2 + redius * CGFloat(aa) ,
            y: bounds.midY - imageW/2 + redius * CGFloat(ss),
            width: imageW,
            height: imageW)
        lockImgLyer.contents = myImage

    }
    
    func updateunLockImg(_ newPointerAngle: CGFloat) {

        let qqqq = CGFloat(Double.pi*2)  / CGFloat(360) * newPointerAngle
        let bounds = lockLayer.bounds
        let myImage = UIImage.SVGImage(named: "icon_unlock")?.cgImage

        let ss = sin(qqqq)
        let aa = cos(qqqq)

        let  imageW = bounds.width/10
        let  redius = bounds.width/2

        unlockImgLyer.frame = CGRect(
            x: bounds.midX - imageW/2 + redius * CGFloat(aa) ,
            y: bounds.midY - imageW/2 + redius * CGFloat(ss),
            width: imageW,
            height: imageW)
        unlockImgLyer.contents = myImage
        unlockImgLyer.backgroundColor = UIColor.clear.cgColor
    }

    private func updateCentLock() {
        let bounds = centerBigLayer.bounds
        let myImage = UIImage.CHUIImage(named: "img-knob")?.cgImage

        let  widthRatial = CGFloat(5)/6
        let partialInd =  CGFloat(1)/2 - CGFloat(widthRatial)/2

        centerBigLayer.frame = CGRect(x:bounds.width * CGFloat(partialInd), y: bounds.width * CGFloat(partialInd), width: bounds.width * CGFloat(widthRatial), height: bounds.width * CGFloat(widthRatial))
        centerBigLayer.contents = myImage

    }
    
    private func updatePointerLayerPath() {
        let bounds = lockLayer.bounds
        let pointerLock = UIBezierPath()
        pointerLock.move(to: CGPoint(x: bounds.width  - CGFloat(lockPointerLength) , y: bounds.midY))
        pointerLock.addLine(to: CGPoint(x: bounds.width, y: bounds.midY))
        lockLayer.path = pointerLock.cgPath
        lockLayer.lineWidth = 1
        lockLayer.path = pointerLock.cgPath

    }
    
    func setPointerAngle(_ newPointerAngle: CGFloat) {


        let ss = CGFloat(Double.pi*2)  / CGFloat(360) * newPointerAngle
        let ww = CGFloat(Double.pi*2)  / CGFloat(360) * newPointerAngle   + CGFloat(Double.pi/2)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        lockLayer.transform = CATransform3DMakeRotation(ss, 0, 0, 1)
        centerBigLayer.transform = CATransform3DMakeRotation(ww, 0, 0, 1)

        CATransaction.commit()
    }

    private func updateTrackLayerPath() {
        let bounds = trackLayer.bounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2
        let ring = UIBezierPath(arcCenter: center, radius: radius,
                                startAngle: 0,
                                endAngle: CGFloat(Double.pi) * 2, clockwise: true)


        trackLayer.path = ring.cgPath
    }
    
    deinit {
        L.d("SesameView deinit")
    }
}
