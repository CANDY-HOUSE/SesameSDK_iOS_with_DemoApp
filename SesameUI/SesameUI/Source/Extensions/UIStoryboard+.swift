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

    private static let storyboard = UIStoryboard(name: "Main",bundle: nil)

    enum viewControllers {
        static var generalTabViewController: GeneralTabViewController? {
            UIStoryboard.storyboard.instantiateViewController(withIdentifier: "GeneralTabViewController") as? GeneralTabViewController
        }

        static var changeValueDialog: ChangeValueDialog? {
            UIStoryboard.storyboard.instantiateViewController(withIdentifier: "ChangeValueDialog") as? ChangeValueDialog
        }

        static var changeIRControlDialog: ChangeIRControlDialog? {
            (UIStoryboard.storyboard.instantiateViewController(withIdentifier: "ChangeIRControlDialog") as! ChangeIRControlDialog)
        }
    }
}
