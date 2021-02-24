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
    
    func presentCHAlertWith(_ oldValue: String,
                            title: String,
                            hint: String,
                            secondOldValue: String,
                            secondHint: String,
                            callback: @escaping (_ newValue: String, _ secondNewValue: String) -> Void) {
        let setValueDialog = UIStoryboard.viewControllers.changeValuesDialog!
        setValueDialog.callback = callback
        setValueDialog.titleLBText = title
        
        setValueDialog.valueDescription = hint
        setValueDialog.value = oldValue
        
        setValueDialog.secondValue = secondOldValue
        setValueDialog.secondValueDescription = secondHint
        
        setValueDialog.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        setValueDialog.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        self.present(setValueDialog, animated: true, completion: nil)
    }
}
