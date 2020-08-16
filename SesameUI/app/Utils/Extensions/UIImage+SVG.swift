//
//  UIImage+SVG.swift
//  WeChatSwift
//
//  Created by xu.shuifeng on 2019/7/3.
//  Copyright © 2019 alexiscn. All rights reserved.
//

import UIKit
import SVGKit

extension UIImage {
    
    static func CHUIImage(named: String) -> UIImage? {
        UIImage(named: named, in: Constant.resourceBundle, compatibleWith: nil)
    }
    
    static func SVGImage(named: String,
                         fillColor: UIColor? = nil,
                         size: CGSize? = nil) -> UIImage? {
        if let url = Constant.resourceBundle.url(forResource: named, withExtension: "svg") {
            let image = SVGKImage(contentsOf: url)
            if let color = fillColor {
                image?.fill(color: color)
            }
            
            if let size = size {
                UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
                let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                image?.uiImage.draw(in: rect)
                let newImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return newImage
            }
            
            return image?.uiImage.withRenderingMode(.alwaysOriginal)
        }
        return nil
    }
    
    static func imageFromColor(_ color: UIColor, transparent: Bool = true, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        let path = UIBezierPath(rect: rect)
        UIGraphicsBeginImageContextWithOptions(rect.size, !transparent, UIScreen.main.scale)
        
        var image: UIImage?
        if let context = UIGraphicsGetCurrentContext() {
            context.addPath(path.cgPath)
            context.setFillColor(color.cgColor)
            context.fillPath()
            image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return image
    }
}
