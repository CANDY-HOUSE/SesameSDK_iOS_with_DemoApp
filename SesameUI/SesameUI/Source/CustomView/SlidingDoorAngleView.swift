//
//  SlidingDoorAngleView.swift
//  SesameUI
//
//  Created by frey Mac on 2026/2/11.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import UIKit

final class SlidingDoorAngleView: UIView {
    
    private let lockImage = UIImage.SVGImage(named: "icon_lock") ?? UIImage()
    private let unlockImage = UIImage.SVGImage(named: "icon_unlock") ?? UIImage()
    
    private let innerColor = UIColor(hex: 0xE7E6EB)
    private let sliderColor = UIColor(hex: 0xC2BEC6)
    
    private let iconSize: CGFloat = 28
    private let iconGap: CGFloat = 18
    
    // 门体宽（瘦一些可调小）
    private let bodyWidth: CGFloat = 118
    
    // 上下 padding（小一些=更长）
    private let bodyTopBottomPadding: CGFloat = 10
    
    private let sliderSidePadding: CGFloat = 6
    private let cornerRadius: CGFloat = 22
    
    private let lineWidth: CGFloat = 4
    private let lineInsetRatio: CGFloat = 0.18
    
    // Android 风格关键：门体右边界比例（0.70 左右微调即可）
    private let bodyRightRatio: CGFloat = 0.70
    
    // MARK: - State
    private var progress: CGFloat = 0
    private var lockProgress: CGFloat = 0.5
    private var unlockProgress: CGFloat = 0.5
    
    private var observedMin: CGFloat?
    private var observedMax: CGFloat?
    private var lastLock: Int16?
    private var lastUnlock: Int16?
    
    // MARK: - Init
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
        isOpaque = false
        clipsToBounds = false
        contentMode = .redraw
    }
    
    // MARK: - Public
    func update(pos: Int16, lock: Int16, unlock: Int16) {
        let p = CGFloat(pos)
        let lp = CGFloat(lock)
        let up = CGFloat(unlock)
        
        observedMin = [observedMin, p, lp, up].compactMap { $0 }.min()
        observedMax = [observedMax, p, lp, up].compactMap { $0 }.max()
        
        var minV = observedMin ?? p
        var maxV = observedMax ?? p
        
        let minSpan: CGFloat = 20
        if maxV - minV < minSpan {
            let c = (maxV + minV) / 2
            minV = c - minSpan / 2
            maxV = c + minSpan / 2
        }
        
        progress = norm(p, minV, maxV)
        
        // icons only move when lock/unlock changes (match Android)
        if lastLock == nil || lastLock != lock {
            lockProgress = norm(lp, minV, maxV)
            lastLock = lock
        }
        if lastUnlock == nil || lastUnlock != unlock {
            unlockProgress = norm(up, minV, maxV)
            lastUnlock = unlock
        }
        
        setNeedsDisplay()
    }
    
    // MARK: - Draw
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()
        ctx.interpolationQuality = .high
        ctx.setShouldAntialias(true)
        
        let w = rect.width
        
        let bodyRight = w * bodyRightRatio
        let bodyLeft = bodyRight - bodyWidth
        
        let bodyTop = bodyTopBottomPadding
        let bodyH = max(0, rect.height - bodyTopBottomPadding * 2)
        
        let bodyRect = CGRect(x: bodyLeft, y: bodyTop, width: bodyWidth, height: bodyH)
        
        // body background
        ctx.setFillColor(innerColor.cgColor)
        UIBezierPath(roundedRect: bodyRect, cornerRadius: cornerRadius * 0.8).fill()
        
        // slider
        let sliderH = bodyRect.height * 0.42
        let trackTop = bodyRect.minY
        let trackBottom = bodyRect.maxY - sliderH
        let sliderTop = trackTop + (trackBottom - trackTop) * (1 - progress)
        
        let sliderRect = CGRect(
            x: bodyRect.minX + sliderSidePadding,
            y: sliderTop,
            width: bodyRect.width - sliderSidePadding * 2,
            height: sliderH
        )
        
        ctx.setFillColor(sliderColor.cgColor)
        UIBezierPath(roundedRect: sliderRect, cornerRadius: cornerRadius * 0.9).fill()
        
        // white line
        let lineY = sliderRect.midY
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(lineWidth)
        ctx.setLineCap(.round)
        
        let lineStartX = sliderRect.minX + sliderRect.width * lineInsetRatio
        let lineEndX = sliderRect.maxX - sliderRect.width * lineInsetRatio
        ctx.move(to: CGPoint(x: lineStartX, y: lineY))
        ctx.addLine(to: CGPoint(x: lineEndX, y: lineY))
        ctx.strokePath()
        
        // icons (right)
        let iconX = bodyRect.maxX + iconGap
        
        func drawIcon(_ img: UIImage, p: CGFloat) {
            let clamped = max(min(p, 1), 0)
            let y = trackTop + (trackBottom - trackTop) * (1 - clamped) + sliderH / 2
            let x = round(iconX)
            let yy = round(y - iconSize / 2)
            img.draw(in: CGRect(x: x, y: yy, width: iconSize, height: iconSize))
        }
        
        drawIcon(unlockImage, p: unlockProgress)
        drawIcon(lockImage, p: lockProgress)
        
        ctx.restoreGState()
    }
    
    // MARK: - Utils
    private func norm(_ v: CGFloat, _ minV: CGFloat, _ maxV: CGFloat) -> CGFloat {
        guard maxV - minV != 0 else { return 0.5 }
        let t = (v - minV) / (maxV - minV)
        return Swift.max(Swift.min(t, 1), 0)
    }
}

private extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: alpha
        )
    }
}
