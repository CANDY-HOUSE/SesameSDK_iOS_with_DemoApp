//
//  IndicatorGenerator.swift
//  SesameUI
//
//  Created by eddy on 2023/12/18.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

/// 加載樣式類型
enum LoadingStyle {
//    旋轉縮放的 ball
    case ballClipRotatePulse
//    系統自帶 loading
    case activityIndicator
//    系統自帶 refreshControl
    case scalingIndicator
}

// 加載指示器工廠
enum IndicatorGenerator {
    
    static func indicator(style: LoadingStyle) -> UIView {
        switch style {
        case .ballClipRotatePulse:
            return ballClipRotatePulse()
        default:
            return activityIndicator()
        }
    }
    
    private static func ballClipRotatePulse() -> UIView {
        let w = 30
        let view = ActivityIndicatorView(contentColor: UIColor.sesame2Green, contentSize: .init(width: w, height: w))
        view.contentColor = UIColor.sesame2Green
        view.contentSize = .init(width: w, height: w)
        view.startAnimation()
        return view
    }
    
    private static func activityIndicator() -> UIView {
        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.startAnimating()
        return indicator
    }
    
    private static func scalingIndicator() -> UIView {
        return UIRefreshControl()
    }
}
