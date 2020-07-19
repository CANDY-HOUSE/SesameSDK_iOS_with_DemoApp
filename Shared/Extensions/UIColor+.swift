//
//  UIColor+.swift
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

extension UIColor {
    public static let sesame2Green = UIColor(hexString: "#28aeb1")
    public static let sesame2Gray = rgba(red: 242, green: 242, blue: 247, alpha: 1)
    public static let sesame2LightGray = UIColor(hexString: "#CCCCCC")
    public static let lockYellow = UIColor(rgb: 0xf9e074)
    public static let lockRed = UIColor(rgb: 0xcc4a44)
    public static let lockGreen = UIColor.sesame2Green
    public static let lockGray = UIColor(rgb: 0xe4e3e3)
    
    #if os(iOS)
    public static let sesame2DarkText = UIColor.darkText
    #elseif os(watchOS)
    public static let sesame2DarkText = UIColor.black
    #endif
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }

    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
    class func rgba(red: Int, green: Int, blue: Int, alpha: CGFloat) -> UIColor{
        return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }
}
