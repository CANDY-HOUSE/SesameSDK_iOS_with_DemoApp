//
//  IREmitView.swift
//  SesameUI
//
//  Created by eddy on 2024/1/2.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

class StrokeAnimation: CABasicAnimation {
    override init() {
        super.init()
    }
    
    init(type: StrokeType,
         beginTime: Double = 0.0,
         fromValue: CGFloat,
         toValue: CGFloat,
         duration: Double) {
        
        super.init()
        
        self.keyPath = type == .start ? "strokeStart" : "strokeEnd"
        
        self.beginTime = beginTime
        self.fromValue = fromValue
        self.toValue = toValue
        self.duration = duration
        self.timingFunction = .init(name: .easeInEaseOut)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    enum StrokeType {
        case start
        case end
    }
}


class PlayLoadingView: UIView {
    private var isLoading = false
    private lazy var shapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = 1
        layer.strokeColor = UIColor.sesame2Green.cgColor
        layer.lineCap = .round
        return layer
    }()
    
    private lazy var playShapePath = {
        let path = UIBezierPath()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 6
        path.move(to: CGPoint(x: center.x - radius / 2, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x - radius / 2, y: center.y + radius))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.close()
        return path
    }()
    
    private lazy var loadingShapePath = {
        let midX = CGRectGetMidX(self.bounds)
        let path = UIBezierPath(arcCenter: CGPointMake(midX, midX), radius: midX / 2.2, startAngle: -0.5 * .pi, endAngle: 1.5 * .pi, clockwise: true)
        UIColor.white.setFill()
        path.fill()

        return path
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        setupLayer()
        drawPlayShape()
    }
    
    private func commitChange(block: @escaping () -> ()) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        block()
        CATransaction.commit()
    }
    
    private func setupLayer() {
        layer.addSublayer(shapeLayer)
    }
    
    override func draw(_ rect: CGRect) {
        UIColor.lockGray.setStroke()
        let circlePath = UIBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
        circlePath.lineWidth = 1
        circlePath.stroke()
    }
    
    private func drawPlayShape() {
        commitChange { [weak self] in
            guard let self = self else { return }
            self.shapeLayer.fillColor = UIColor.sesame2Green.cgColor
            self.shapeLayer.path = self.playShapePath.cgPath
        }
    }
    
    private func drawLoadingShape() {
        commitChange { [weak self] in
            guard let self = self else { return }
            self.shapeLayer.fillColor = UIColor.white.cgColor
            self.shapeLayer.path = self.loadingShapePath.cgPath
        }
    }
    
    private func animateStroke() {
        let startAnimation = StrokeAnimation(
            type: .start,
            beginTime: 0.5,
            fromValue: 0.0,
            toValue: 1.0,
            duration: 1.0
        )
        let endAnimation = StrokeAnimation(
            type: .end,
            fromValue: 0.0,
            toValue: 1.0,
            duration: 1.0
        )
        let strokeAnimationGroup = CAAnimationGroup()
        strokeAnimationGroup.duration = 1.5
        strokeAnimationGroup.isRemovedOnCompletion = false
        strokeAnimationGroup.repeatDuration = .infinity
        strokeAnimationGroup.animations = [startAnimation, endAnimation]
        shapeLayer.add(strokeAnimationGroup, forKey: "loadingGroupAnimation")
    }
    
    private func startAnimation() {
        animateStroke()
    }
    
    private func stopAnimation() {
        shapeLayer.removeAnimation(forKey: "loadingGroupAnimation")
    }
    
    func toggleState() {
        isLoading.toggle()
        isLoading ? playing() : pause()
    }
    
    func playing() {
        if isLoading { return }
        isLoading = true
        drawLoadingShape()
        startAnimation()
    }
    
    func pause() {
        if !isLoading { return }
        isLoading = false
        stopAnimation()
        drawPlayShape()
    }
}
