//
//  UIStoryboard+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

public extension UIStoryboard {
    private static let storyboardName = "Main"
    private static let wifiStoryboardName = "Wifi"
    private static let storyboard = UIStoryboard(name: UIStoryboard.storyboardName,
                                                 bundle: Bundle.resourceBundle)
    private static let wifiStoryboard = UIStoryboard(name: UIStoryboard.wifiStoryboardName,
                                                     bundle: Bundle.resourceBundle)
    
    enum viewControllers {
        static var generalTabViewController: GeneralTabViewController? {
            UIStoryboard.storyboard.instantiateViewController(withIdentifier: "GeneralTabViewController") as? GeneralTabViewController
        }
        
        static var changeValueDialog: ChangeValueDialog? {
            UIStoryboard.storyboard.instantiateViewController(withIdentifier: "ChangeValueDialog") as? ChangeValueDialog
        }
        
        static var changeValuesDialog: ChangeValuesDialog? {
            UIStoryboard.storyboard.instantiateViewController(withIdentifier: "ChangeValuesDialog") as? ChangeValuesDialog
        }
    }
}
