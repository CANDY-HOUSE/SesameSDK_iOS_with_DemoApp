//
//  CHSesame2ChangeNameDialog.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2020/1/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

public class SetValueDialog: UIViewController {
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    var callBack:(_ first:String)->Void = {f in
        L.d("test 閉包")
    }
    var value: String =  ""

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueDescriptionLabel: UILabel!
    @IBOutlet weak var valueTextField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    
    var titleLBText: String = "co.candyhouse.sesame-sdk-test-app.ChangeSesameName".localized
    var firstHintLBText: String = "co.candyhouse.sesame-sdk-test-app.GiveSesameAName".localized

    @IBAction func okTapped(_ sender: Any) {
        if let value = valueTextField.text {

            if(value == ""){
                return
            }

            self.callBack(value)
            self.dismiss(animated: true, completion: nil)
        }
    }


    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        valueDescriptionLabel.text = firstHintLBText
        titleLabel.text = titleLBText
        cancelButton.setTitle("co.candyhouse.sesame-sdk-test-app.Cancel".localized, for: .normal)
        okButton.setTitle("co.candyhouse.sesame-sdk-test-app.OK".localized.localized, for: .normal)
        titleLabel.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        okButton.titleLabel?.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        cancelButton.titleLabel?.font = .boldSystemFont(ofSize: UIFont.labelFontSize)


        valueTextField.text = value
    }
    
    static func show(_ name: String,
                     callBack:@escaping (_ first: String)->Void){
        let myAlert = UIStoryboard.viewControllers.chSesame2ChangeNameDialog!
        myAlert.callBack = callBack
        myAlert.value = name

        myAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        myAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(myAlert, animated: true, completion: nil)
        } else {
            UIApplication.shared.delegate?.window??.rootViewController?.present(myAlert, animated: true, completion: nil)
        }
    }
    
    static func show(_ name: String, title: String, hint: String, callBack:@escaping (_ first:String)->Void){
        let myAlert = UIStoryboard.viewControllers.chSesame2ChangeNameDialog!
        myAlert.titleLBText = title
        myAlert.firstHintLBText = hint
        myAlert.callBack = callBack
        myAlert.value = name

        myAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        myAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(myAlert, animated: true, completion: nil)
        } else {
            UIApplication.shared.delegate?.window??.rootViewController?.present(myAlert, animated: true, completion: nil)
        }
    }
}
