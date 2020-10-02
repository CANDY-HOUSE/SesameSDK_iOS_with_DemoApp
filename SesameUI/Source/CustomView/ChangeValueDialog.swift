//
//  CHSesame2ChangeNameDialog.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2020/1/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

public class ChangeValueDialog: UIViewController {
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    var callBack:(_ newValue: String) -> Void = { newValue in
        
    }
    var value: String =  ""

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueDescriptionLabel: UILabel!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    
    var titleLBText: String = "co.candyhouse.sesame-sdk-test-app.ChangeSesameName".localized
    var valueDescription: String = "co.candyhouse.sesame-sdk-test-app.GiveSesameAName".localized

    @IBAction func okTapped(_ sender: Any) {
        if let newValue = valueTextField.text,
            newValue != "" {
            self.callBack(newValue)
            self.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        valueDescriptionLabel.text = valueDescription
        titleLabel.text = titleLBText
        cancelButton.setTitle("co.candyhouse.sesame-sdk-test-app.Cancel".localized, for: .normal)
        okButton.setTitle("co.candyhouse.sesame-sdk-test-app.OK".localized.localized, for: .normal)
        titleLabel.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        okButton.titleLabel?.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        cancelButton.titleLabel?.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        valueTextField.text = value
    }
    
    static func show(_ oldValue: String,
                     callBack: @escaping (_ newValue: String)->Void) {
        
        let myAlert = UIStoryboard.viewControllers.changeValueDialog!
        myAlert.value = oldValue
        myAlert.callBack = callBack
        myAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        myAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(myAlert, animated: true, completion: nil)
        } else {
            UIApplication.shared.delegate?.window??.rootViewController?.present(myAlert, animated: true, completion: nil)
        }
    }
    
    static func show(_ oldValue: String,
                     title: String,
                     hint: String,
                     callBack:@escaping (_ newValue: String)->Void){
        let setValueDialog = UIStoryboard.viewControllers.changeValueDialog!
        setValueDialog.titleLBText = title
        setValueDialog.valueDescription = hint
        setValueDialog.callBack = callBack
        setValueDialog.value = oldValue
        
        setValueDialog.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        setValueDialog.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(setValueDialog, animated: true, completion: nil)
        } else {
            UIApplication.shared.delegate?.window??.rootViewController?.present(setValueDialog, animated: true, completion: nil)
        }
    }
}
