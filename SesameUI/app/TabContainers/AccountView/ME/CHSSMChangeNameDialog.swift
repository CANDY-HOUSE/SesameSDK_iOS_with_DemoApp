//
//  CHSSMChangeNameDialog.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2020/1/13.
//  Copyright © 2020 Cerberus. All rights reserved.
//

import Foundation
import UIKit

public class CHSSMChangeNameDialog: UIViewController {
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    var callBack:(_ first:String)->Void = {f in
        L.d("test 閉包")
    }
    var ssmName:String =  ""

    @IBOutlet weak var firstHintLB: UILabel!
    @IBOutlet weak var titleLB: UILabel!
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var cancelBTN: UIButton!
    @IBOutlet weak var okBTN: UIButton!

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
        firstHintLB.text = "Give Sesame a cooool name! 😎".localStr
        titleLB.text = "Change Sesame Name".localStr
        cancelBTN.setTitle("Cancel".localStr, for: .normal)
        okBTN.setTitle("OK".localStr, for: .normal)
        titleLB.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        okBTN.titleLabel?.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        cancelBTN.titleLabel?.font = .boldSystemFont(ofSize: UIFont.labelFontSize)


        nameTF.text = ssmName
    }
    static func show(_ name: String, callBack:@escaping (_ first:String)->Void){
        let storyboard = Constant.storyboard
        let myAlert = storyboard.instantiateViewController(withIdentifier: "ssmalert") as! CHSSMChangeNameDialog

        myAlert.callBack = callBack
        myAlert.ssmName = name

        myAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        myAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(myAlert, animated: true, completion: nil)
        } else {
            UIApplication.shared.delegate?.window??.rootViewController?.present(myAlert, animated: true, completion: nil)
        }
    }
}
