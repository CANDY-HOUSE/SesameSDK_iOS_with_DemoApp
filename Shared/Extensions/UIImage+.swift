//
//  UIImage+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/8.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

extension UIImage{

    public func changeColor(_ color : UIColor) -> UIImage{

        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)

        color.setFill()

        let bounds = CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height)

        UIRectFill(bounds)

        self.draw(in: bounds, blendMode: CGBlendMode.destinationIn, alpha: 1.0)

        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let image = tintedImage else {
            return UIImage()
        }

        return image
    }
    
    func circleImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: size.height/2).addClip()
        draw(in: rect)
        let circleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return circleImage
    }
    
    func rectangleImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: 20).addClip()
        draw(in: rect)
        let circleImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return circleImage
    }
    
    func withBackground(color: UIColor, opaque: Bool = true) -> UIImage {
      UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
          
      guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
      defer { UIGraphicsEndImageContext() }
          
      let rect = CGRect(origin: .zero, size: size)
      ctx.setFillColor(color.cgColor)
      ctx.fill(rect)
      ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
      ctx.draw(image, in: rect)
          
      return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
    
    func addImagePadding(x: CGFloat, y: CGFloat) -> UIImage? {
        let width: CGFloat = size.width + x
        let height: CGFloat = size.height + y
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        let origin: CGPoint = CGPoint(x: (width - size.width) / 2, y: (height - size.height) / 2)
        draw(at: origin)
        let imageWithPadding = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return imageWithPadding
    }
    
#if os(iOS)
    public class func generateQRCode(_ text: String,_ fillImage: UIImage? = nil, _ color:UIColor? = nil) -> UIImage? {

        guard let data = text.data(using: .utf8) else {
            return nil
        }

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")

            // value = @"L/M/Q/H"
            filter.setValue("M", forKey: "inputCorrectionLevel")

            guard let outPutImage = filter.outputImage else {
                return nil
            }


            let scale = UIScreen.main.bounds.width/outPutImage.extent.width

            let transform = CGAffineTransform(scaleX: scale, y: scale)

            let output = outPutImage.transformed(by: transform)

            let QRCodeImage = UIImage(ciImage: output)

            guard let fillImage = fillImage else {
                return QRCodeImage
            }

            let imageSize = QRCodeImage.size

            UIGraphicsBeginImageContext(imageSize)

            QRCodeImage.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))

            let fillRect = CGRect(x: ( UIScreen.main.bounds.width -  UIScreen.main.bounds.width/5)/2, y: ( UIScreen.main.bounds.width -  UIScreen.main.bounds.width/5)/2, width:  UIScreen.main.bounds.width/5, height:  UIScreen.main.bounds.width/5)

            fillImage.draw(in: fillRect)

            guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return QRCodeImage }

            UIGraphicsEndImageContext()

            return newImage

        }

        return nil

    }

    public class func generateCode128(_ text:String, _ size:CGSize,_ color:UIColor? = nil ) -> UIImage?
    {
        guard let data = text.data(using: .utf8) else {
            return nil
        }

        if let filter = CIFilter(name: "CICode128BarcodeGenerator") {

            filter.setDefaults()

            filter.setValue(data, forKey: "inputMessage")

            guard let outPutImage = filter.outputImage else {
                return nil
            }

            let colorFilter = CIFilter(name: "CIFalseColor", parameters: ["inputImage":outPutImage,"inputColor0":CIColor(cgColor: color?.cgColor ?? UIColor.black.cgColor),"inputColor1":CIColor(cgColor: UIColor.clear.cgColor)])

            guard let newOutPutImage = colorFilter?.outputImage else {
                return nil
            }

            let scaleX:CGFloat = size.width/newOutPutImage.extent.width

            let scaleY:CGFloat = size.height/newOutPutImage.extent.height

            let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)

            let output = newOutPutImage.transformed(by: transform)

            let barCodeImage = UIImage(ciImage: output)

            return barCodeImage

        }

        return nil
    }
    
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else {
            return nil
        }
        self.init(cgImage: cgImage)
    }

class func imageWithLabel(label: UILabel) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0.0)
    label.layer.render(in: UIGraphicsGetCurrentContext()!)
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return img
}
#endif
}
