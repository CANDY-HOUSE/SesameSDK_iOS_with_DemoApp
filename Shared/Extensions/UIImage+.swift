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

#if os(iOS)
    public class func generateQRCode(_ text: String,_ fillImage:UIImage? = nil, _ color:UIColor? = nil) -> UIImage? {

        guard let data = text.data(using: .utf8) else {
            return nil
        }

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")

            // value = @"L/M/Q/H"
            filter.setValue("H", forKey: "inputCorrectionLevel")

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
#endif
}
