//
//  UIImage+SVG.swift
//  WeChatSwift
//
//  Created by xu.shuifeng on 2019/7/3.
//  Copyright © 2019 alexiscn. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import WatchKit
#endif

extension UIImage {
    
    static func CHUIImage(named: String) -> UIImage? {
        #if os(iOS)
        return UIImage(named: named, in: Bundle.resourceBundle, compatibleWith: nil)
        #else
        return UIImage(named: named, in: Bundle.resourceBundle, with: nil)
        #endif
        
        
        // UIImage(named: named, in: Bundle.resourceBundle, compatibleWith: nil)
    }
    
    static func SVGImage(named: String,
                         fillColor: UIColor? = nil,
                         size: CGSize? = nil) -> UIImage? {

        let image = CHUIImage(named: named)
        if let color = fillColor {
            if #available(iOS 13.0, *) {
                return image?.withTintColor(color)
            } else {
                return image?.maskWithColor(color: color)
            }
        }
        return image
    }
    
    private func maskWithColor(color: UIColor) -> UIImage? {
        let maskImage = cgImage!
        
        let width = size.width
        let height = size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        
        context.clip(to: bounds, mask: maskImage)
        context.setFillColor(color.cgColor)
        context.fill(bounds)
        
        if let cgImage = context.makeImage() {
            let coloredImage = UIImage(cgImage: cgImage)
            return coloredImage
        } else {
            return nil
        }
    }
}
