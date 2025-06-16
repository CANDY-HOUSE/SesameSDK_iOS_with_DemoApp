//
//  CHSesameTouchPro+.swift
//  SesameUI
//
//  Created by eddy on 2024/10/12.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

extension CHSesameTouchPro {
    var displayedState: NSAttributedString? {
        get {
            guard self.productModel == .openSensor, deviceStatus == .noBleSignal() else {
                return nil
            }
            if let data = mechStatus?.data {
                do {
                    let state = try JSONDecoder().decode(OpenSensorData.self, from: data)
                    let status = state.Status
                    let timeStr = "\(state.TimeStamp)".localizedTime()
                    let dateString = timeStr?.split(separator: "@").first!
                    let timeString = timeStr?.split(separator: "@").last!
                    let attributedString = NSMutableAttributedString(string: "\(status)\n")
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .center
                    let attributesCenter: [NSAttributedString.Key: Any] = [
                        .paragraphStyle: paragraphStyle,
                    ]
                    attributedString.append(NSAttributedString(string: "\(dateString!)\n\(timeString!)"))
                    attributedString.addAttributes(attributesCenter, range: NSRange(location: 0, length: attributedString.length))
                    let attributesFont: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 20),
                        .foregroundColor: UIColor.lockGray
                    ]
                    attributedString.addAttributes(attributesFont, range: (attributedString.string as NSString).range(of: status))
                    return attributedString
                } catch {}
                return nil
            }
            return nil
        }
    }
}
