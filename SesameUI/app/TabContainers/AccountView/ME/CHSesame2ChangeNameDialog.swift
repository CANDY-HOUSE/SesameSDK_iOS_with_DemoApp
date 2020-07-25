//
//  CHSesame2ChangeNameDialog.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2020/1/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

public class CHSesame2ChangeNameDialog: UIViewController {
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    var callBack:(_ first:String)->Void = {f in
        L.d("test 閉包")
    }
    var sesame2Name:String =  ""

    @IBOutlet weak var firstHintLB: UILabel!
    @IBOutlet weak var titleLB: UILabel!
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var cancelBTN: UIButton!
    @IBOutlet weak var okBTN: UIButton!
    
    var titleLBText: String = "co.candyhouse.sesame-sdk-test-app.ChangeSesameName".localized
    var firstHintLBText: String = "co.candyhouse.sesame-sdk-test-app.GiveSesameAName".localized

    @IBAction func onOKCLick(_ sender: Any) {
        if let first = nameTF.text {

            if(first == ""){
                return
            }

            self.callBack(first)
            self.dismiss(animated: true, completion: nil)
        }
    }


    @IBAction func cancleClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        firstHintLB.text = firstHintLBText
        titleLB.text = titleLBText
        cancelBTN.setTitle("co.candyhouse.sesame-sdk-test-app.Cancel".localized, for: .normal)
        okBTN.setTitle("co.candyhouse.sesame-sdk-test-app.OK".localized.localized, for: .normal)
        titleLB.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        okBTN.titleLabel?.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        cancelBTN.titleLabel?.font = .boldSystemFont(ofSize: UIFont.labelFontSize)


        nameTF.text = sesame2Name
    }
    
    static func show(_ name: String, callBack:@escaping (_ first:String)->Void){
        let myAlert = UIStoryboard.viewControllers.chSesame2ChangeNameDialog!
        myAlert.callBack = callBack
        myAlert.sesame2Name = name

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
        myAlert.sesame2Name = name

        myAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        myAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(myAlert, animated: true, completion: nil)
        } else {
            UIApplication.shared.delegate?.window??.rootViewController?.present(myAlert, animated: true, completion: nil)
        }
    }
}
