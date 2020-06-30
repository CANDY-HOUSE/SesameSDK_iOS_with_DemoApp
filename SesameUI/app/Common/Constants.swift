//
//  Constants.swift
//
//  Created by xu.shuifeng on 2019/7/4.
//  Copyright © 2019 alexiscn. All rights reserved.
//

import UIKit

struct Constants {

    static let screenHeight = UIScreen.main.bounds.height
    static let screenWidth = UIScreen.main.bounds.width
    static var screenSize: CGSize {
        return CGSize(width: screenWidth, height: screenHeight)
    }
    
    static let iPhoneX = UIScreen.main.bounds.height >= 812
    
    static let lineHeight = 1/UIScreen.main.scale
    
    static var bottomInset: CGFloat {
        return iPhoneX ? 34.0: 0.0
    }
    
    static var topInset: CGFloat {
        return iPhoneX ? 44.0: 0.0
    }
    
    static var statusBarHeight: CGFloat {
        return iPhoneX ? 44.0: 20.0
    }

}
