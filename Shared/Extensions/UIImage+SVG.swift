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
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: self.size.height);
        context.scaleBy(x: 1.0, y: -1.0);
        context.setBlendMode(.normal);
        let rect = CGRect(x: 0, y:0, width: self.size.width, height: self.size.height)
        context.clip(to: rect, mask: self.cgImage!)
        color.setFill()
        context.fill(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
