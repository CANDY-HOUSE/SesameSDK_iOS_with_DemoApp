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
    static func SVGImage(named: String,
                         fillColor: UIColor? = nil,
                         size: CGSize? = nil) -> UIImage? {
        let image = UIImage(named: named)
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
    
    private class func gifImageWithData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return animatedImageWithSource(source)
    }
    
    private class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [UIImage]()
        var duration = 0.0
        for i in 0..<count {
            guard let image = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            guard let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                  let gifDictionary = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                  let frameDuration = gifDictionary[kCGImagePropertyGIFDelayTime as String] as? Double
            else { continue }
            duration += frameDuration
            images.append(UIImage(cgImage: image))
        }
        return UIImage.animatedImage(with: images, duration: duration)
    }
    
    static func gif(asset: String) -> UIImage? {
        if let asset = NSDataAsset(name: asset) {
            return gifImageWithData(asset.data)
        }
        return nil
    }
}
