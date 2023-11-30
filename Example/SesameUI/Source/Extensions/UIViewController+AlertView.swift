//
//  UIViewController+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/12/16.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

extension UIViewController {
    func presentCHAlertWithPlaceholder(title: String,
                                       placeholder: String,
                                       hint: String,
                                       callback: @escaping (_ newValue: String)->Void,
                                       cancelHandler: (()->Void)?=nil) {
        let myAlert = UIStoryboard.viewControllers.changeValueDialog!
        myAlert.value = placeholder
        myAlert.titleLBText = title
        myAlert.valueDescription = hint
        myAlert.callback = callback
        myAlert.cancelHandler = cancelHandler
        myAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        myAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        self.present(myAlert, animated: true, completion: nil)
    }
}
