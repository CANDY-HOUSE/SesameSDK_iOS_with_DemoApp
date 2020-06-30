//
//  ScanView.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2020/1/6.
//  Copyright © 2020 Cerberus. All rights reserved.
//

import UIKit
public class ScanView: UIView {

    lazy var scanAnimationImage = UIImage()
    public lazy var cornerLocation: CornerLocation = .default
    public lazy var borderColor: UIColor = .white
    public lazy var borderLineWidth:CGFloat = 0.2
    public lazy var cornerColor: UIColor = .sesameGreen
    public lazy var cornerWidth:CGFloat = 0.0
    public lazy var backgroundAlpha:CGFloat = 0.6
    lazy var scanBorderWidth = 0.6 * screenWidth
    lazy var scanBorderHeight = scanBorderWidth
    lazy var scanBorderX = 0.5 * (1 - 0.6) * screenWidth
    lazy var scanBorderY = 0.4 * (screenHeight - scanBorderWidth)
    lazy var contentView = UIView(frame: CGRect(x: scanBorderX, y: scanBorderY, width: scanBorderWidth, height:scanBorderHeight))

    override public func layoutSubviews() {
        screenWidth = bounds.size.width
        screenHeight = bounds.size.height
        cornerWidth = 2
        scanBorderWidth = 0.6 * screenWidth
        scanBorderHeight = scanBorderWidth
        scanBorderX = 0.5 * (1 - 0.6) * screenWidth
        scanBorderY = 0.5 * (screenHeight - scanBorderHeight)
        contentView = UIView(frame: CGRect(x: scanBorderX, y: scanBorderY, width: scanBorderWidth, height:scanBorderHeight))
    }

    var screenWidth = Constants.screenWidth
    var screenHeight = Constants.screenHeight

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        drawScan(rect)

        let imageView = UIImageView(image: scanAnimationImage.changeColor(cornerColor))
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true
        addSubview(contentView)

        ScanAnimation.shared.startWith(CGRect(x: 0 , y: 0, width: scanBorderWidth , height: 12), contentView, imageView: imageView)
    }
}

class ScanAnimation:NSObject{

    static let shared:ScanAnimation = {
        let instance = ScanAnimation()
        return instance
    }()

    lazy var animationImageView = UIImageView()
    var displayLink:CADisplayLink?
    var tempFrame:CGRect?
    var contentHeight:CGFloat?
    func startWith(_ rect:CGRect, _ parentView:UIView, imageView:UIImageView) {
        tempFrame = rect
        imageView.frame = tempFrame ?? CGRect.zero
        animationImageView = imageView
        contentHeight = parentView.bounds.height
        parentView.addSubview(imageView)
        setupDisplayLink()
    }


    @objc func animation() {
        if animationImageView.frame.maxY > contentHeight! + 20 {
            animationImageView.frame = tempFrame ?? CGRect.zero
        }
        animationImageView.transform = CGAffineTransform(translationX: 0, y: 2).concatenating(animationImageView.transform)
    }

    func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(animation))
        displayLink?.add(to: .current, forMode: .common)
        displayLink?.isPaused = true
    }

    func startAnimation() {
        displayLink?.isPaused = false
    }

    func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }

}

// MARK: - CustomMethod
extension ScanView{

    func startAnimation() {
        ScanAnimation.shared.startAnimation()
    }

    func stopAnimation() {
        ScanAnimation.shared.stopAnimation()
    }

    func drawScan(_ rect: CGRect) {

        UIColor.black.withAlphaComponent(backgroundAlpha).setFill()
        UIRectFill(rect)

        let context = UIGraphicsGetCurrentContext()

        context?.setBlendMode(.destinationOut)

        let bezierPath = UIBezierPath(rect: CGRect(x: scanBorderX + 0.5 * borderLineWidth, y: scanBorderY + 0.5 * borderLineWidth, width: scanBorderWidth - borderLineWidth, height: scanBorderHeight - borderLineWidth))

        bezierPath.fill()
        // 执行混合模式
        context?.setBlendMode(.normal)
        /// 边框设置
        let borderPath = UIBezierPath(rect: CGRect(x: scanBorderX, y: scanBorderY, width: scanBorderWidth, height: scanBorderHeight))

        borderPath.lineCapStyle = .butt

        borderPath.lineWidth = borderLineWidth

        borderColor.set()
        borderPath.stroke()

        //角标长度
        let cornerLenght:CGFloat = 20
        let insideExcess = 0.5 * (cornerWidth - borderLineWidth)
        let outsideExcess = 0.5 * (cornerWidth + borderLineWidth)

        /// 左上角角标
        let leftTopPath = UIBezierPath()

        leftTopPath.lineWidth = cornerWidth

        cornerColor.set()

        if cornerLocation == .inside {

            leftTopPath.move(to: CGPoint(x: scanBorderX + insideExcess, y: scanBorderY + cornerLenght + insideExcess))

            leftTopPath.addLine(to: CGPoint(x: scanBorderX + insideExcess, y: scanBorderY + insideExcess))

            leftTopPath.addLine(to: CGPoint(x: scanBorderX + cornerLenght + insideExcess, y: scanBorderY + insideExcess))

        }else if cornerLocation == .outside{

            leftTopPath.move(to: CGPoint(x: scanBorderX - outsideExcess, y: scanBorderY + cornerLenght - outsideExcess))

            leftTopPath.addLine(to: CGPoint(x: scanBorderX - outsideExcess, y: scanBorderY - outsideExcess))

            leftTopPath.addLine(to: CGPoint(x: scanBorderX + cornerLenght - outsideExcess, y: scanBorderY - outsideExcess))

        }else{

            leftTopPath.move(to: CGPoint(x: scanBorderX, y: scanBorderY + cornerLenght))

            leftTopPath.addLine(to: CGPoint(x: scanBorderX, y: scanBorderY))

            leftTopPath.addLine(to: CGPoint(x: scanBorderX + cornerLenght, y: scanBorderY))

        }

        leftTopPath.stroke()

        /// 左下角角标
        let leftBottomPath = UIBezierPath()

        leftBottomPath.lineWidth = cornerWidth

        cornerColor.set()

        if cornerLocation == .inside {

            leftBottomPath.move(to: CGPoint(x: scanBorderX + cornerLenght + insideExcess, y: scanBorderY + scanBorderHeight - insideExcess))

            leftBottomPath.addLine(to: CGPoint(x: scanBorderX + insideExcess, y: scanBorderY + scanBorderHeight - insideExcess))

            leftBottomPath.addLine(to: CGPoint(x: scanBorderX +  insideExcess, y: scanBorderY + scanBorderHeight - cornerLenght - insideExcess))

        }else if cornerLocation == .outside{

            leftBottomPath.move(to: CGPoint(x: scanBorderX + cornerLenght - outsideExcess, y: scanBorderY + scanBorderHeight + outsideExcess))

            leftBottomPath.addLine(to: CGPoint(x: scanBorderX - outsideExcess, y: scanBorderY + scanBorderHeight + outsideExcess))

            leftBottomPath.addLine(to: CGPoint(x: scanBorderX - outsideExcess, y: scanBorderY + scanBorderHeight - cornerLenght + outsideExcess))

        }else{

            leftBottomPath.move(to: CGPoint(x: scanBorderX + cornerLenght, y: scanBorderY + scanBorderHeight))

            leftBottomPath.addLine(to: CGPoint(x: scanBorderX, y: scanBorderY + scanBorderHeight))

            leftBottomPath.addLine(to: CGPoint(x: scanBorderX, y: scanBorderY + scanBorderHeight - cornerLenght))

        }

        leftBottomPath.stroke()

        /// 右上角小图标
        let rightTopPath = UIBezierPath()

        rightTopPath.lineWidth = cornerWidth

        cornerColor.set()

        if cornerLocation == .inside {

            rightTopPath.move(to: CGPoint(x: scanBorderX + scanBorderWidth - cornerLenght - insideExcess, y: scanBorderY + insideExcess))

            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth - insideExcess, y: scanBorderY + insideExcess))

            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth - insideExcess, y: scanBorderY + cornerLenght + insideExcess))

        } else if cornerLocation == .outside {

            rightTopPath.move(to: CGPoint(x: scanBorderX + scanBorderWidth - cornerLenght + outsideExcess, y: scanBorderY - outsideExcess))

            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth + outsideExcess, y: scanBorderY - outsideExcess))

            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth + outsideExcess, y: scanBorderY + cornerLenght - outsideExcess))

        } else {

            rightTopPath.move(to: CGPoint(x: scanBorderX + scanBorderWidth - cornerLenght, y: scanBorderY))

            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth, y: scanBorderY))

            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth, y: scanBorderY + cornerLenght))

        }

        rightTopPath.stroke()

        /// 右下角小图标
        let rightBottomPath = UIBezierPath()

        rightBottomPath.lineWidth = cornerWidth

        cornerColor.set()

        if cornerLocation == .inside {

            rightBottomPath.move(to: CGPoint(x: scanBorderX + scanBorderWidth - insideExcess, y: scanBorderY + scanBorderHeight - cornerLenght - insideExcess))

            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth - insideExcess, y: scanBorderY + scanBorderHeight - insideExcess))

            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth - cornerLenght - insideExcess, y: scanBorderY + scanBorderHeight - insideExcess))

        } else if cornerLocation == .outside {

            rightBottomPath.move(to: CGPoint(x: scanBorderX + scanBorderWidth + outsideExcess, y: scanBorderY + scanBorderHeight - cornerLenght + outsideExcess))

            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth + outsideExcess, y: scanBorderY + scanBorderHeight + outsideExcess))

            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth - cornerLenght + outsideExcess, y: scanBorderY + scanBorderHeight + outsideExcess))

        } else {

            rightBottomPath.move(to: CGPoint(x: scanBorderX + scanBorderWidth, y: scanBorderY + scanBorderHeight - cornerLenght))

            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth, y: scanBorderY + scanBorderHeight))

            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth - cornerLenght, y: scanBorderY + scanBorderHeight))

        }
        rightBottomPath.stroke()
    }

}

public enum CornerLocation {
    case `default`
    case inside
    case outside
}



