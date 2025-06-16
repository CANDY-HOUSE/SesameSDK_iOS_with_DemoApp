//
//  WebRegisterVC.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/25.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import UIKit
import SesameSDK
import WebKit
import AWSCognitoIdentityProvider
import AWSMobileClient

class SignUpViewController: CHBaseViewController , WKNavigationDelegate, WKUIDelegate{

    var loginVC:LogInViewController? = nil
    @IBAction func back(_ sender: Any) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion:nil)
        }
    }

    @IBAction func signup(_ sender: Any) {
        self.view.endEditing(true)
        
        let userAttributes: [String: String] = [
            "email": emailTF.text!.toMail(),
            "given_name": givenNameTF.text!,
            "family_name": userTF.text!
        ]
        
        AWSMobileClient
            .default()
            .signUp(username: emailTF.text!.toMail(),
                    password: passwordTF.text!,
                    userAttributes: userAttributes) { result, error in
                        DispatchQueue.main.async {
                            if let error = error as? AWSMobileClientError {
                                // TODO: Error Handle
                                L.d(ErrorMessage.descriptionFromError(error: error))
                                self.view.makeToast(ErrorMessage.descriptionFromError(error: error))
                            } else if let result = result {
                                switch result.signUpConfirmationState {
                                case .confirmed:
                                    self.view.makeToast("confirmed")
                                case .unconfirmed:
                                    self.view.makeToast("unconfirmed")
                                    
                                    //view group 1
                                    self.userTF.isEnabled = false
                                    self.givenNameTF.isEnabled = false
                                    self.passwordTF.isEnabled = false
                                    self.emailTF.isEnabled = false
                                    self.signupBtn.isEnabled = false
                                    self.signupBtn.backgroundColor = UIColor.lightGray
                                    self.signupBtn.alpha = 0.6
                                    //end view group 1

                                    //view group 2
                                    self.cinfirmTF.isHidden = false // todo test
                                    self.confirmCodeLB.isHidden = false
                                    self.confirmBtn.isHidden = false
                                    self.resendEmailBtn.isHidden = false
                                    //end view group 2

                                    let alertController = UIAlertController(title: "Code Sent",
                                                                            message: "Code sent to \(result.codeDeliveryDetails?.destination ?? "no message")",
                                        preferredStyle: .alert)
                                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                                    alertController.addAction(okAction)
                                    self.present(alertController, animated: true, completion: nil)
                                    
                                case .unknown:
                                    self.view.makeToast("unknown")
                                }
                            } else {
                                self.view.makeToast("Unknow error")
                            }
                        }
        }
    }

    @IBAction func confirmuser(_ sender: Any) {
        AWSMobileClient
            .default()
            .confirmSignUp(username: emailTF.text!.toMail(),
                           confirmationCode: self.cinfirmTF.text!) { signUpResult, error in
                            DispatchQueue.main.async {
                                if let error = error {
                                    self.view.makeToast(ErrorMessage.descriptionFromError(error: error))
                                } else {
                                    self.loginVC?.userName.text = self.emailTF.text!.toMail()
                                    self.loginVC?.password.text = self.passwordTF.text
                                    self.dismiss(animated: true, completion:nil)
                                }
                            }
        }
    }
    
    @IBAction func reSendEmail(_ sender: Any) {
        
        AWSMobileClient
            .default()
            .resendSignUpCode(username: emailTF.text!.toMail()) { signUpResult, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.view.makeToast(ErrorMessage.descriptionFromError(error: error))
                    } else if let result = signUpResult {
                        let alertController = UIAlertController(title: "Code Sent",
                                                                message: "Code resent to \(result.codeDeliveryDetails?.destination! ?? " no message")",
                            preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                        alertController.addAction(okAction)
                        self.present(alertController, animated: true, completion: nil)
                    } else {
                        self.view.makeToast("Unknow error")
                    }
                }
        }
    }
    
    @IBOutlet weak var usernameLb: UILabel!
    @IBOutlet weak var passwordLB: UILabel!
    @IBOutlet weak var mailLB: UILabel!
    @IBOutlet weak var userTF: UITextField!
    @IBOutlet weak var givenNameTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var emailTF: UITextField!
    @IBOutlet weak var cinfirmTF: UITextField!
    @IBOutlet weak var confirmCodeLB: UILabel!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var givenNameLB: UILabel!
    @IBOutlet weak var signupBtn: UIButton!
    @IBOutlet weak var confirmBtn: UIButton!
    @IBOutlet weak var resendEmailBtn: UIButton!

    @objc private func handleRightBarButtonTapped(_ sender: Any) {
        self.view.endEditing(true)
    }
    @objc private func okTapped(_ sender: Any) {
        self.view.endEditing(true)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        L.d("viewDidLoad")
        backBtn.setImage( UIImage.SVGImage(named:"icons_filled_close"), for: .normal)
        userTF.delegate = self
        givenNameTF.delegate = self
        passwordTF.delegate = self
        emailTF.delegate = self
        cinfirmTF.delegate = self
        // Last Name = Family Name = 姓;
        // First Name = Given Name = 名
        mailLB.text = "Email".localStr
        usernameLb.text = "Last Name".localStr
        givenNameLB.text = "First Name".localStr
        passwordLB.text = "Password".localStr
        confirmCodeLB.text = "Verification code".localStr
        signupBtn.setTitle("Sign up".localStr, for: .normal)
        confirmBtn.setTitle("Verification code".localStr, for: .normal)
        resendEmailBtn.setTitle("Re-send verification code".localStr, for: .normal)

        emailTF.text = loginVC?.userName.text
        passwordTF.text = loginVC?.password.text

        if(loginVC!.userisNotConfirmed){
            //view group 1
            givenNameTF.isHidden = true
            userTF.isHidden = true
            signupBtn.isHidden = true
            usernameLb.isHidden = true
            givenNameLB.isHidden = true
            passwordTF.isHidden = true
            passwordLB.isHidden = true
            //end view group 1
            reSendEmail("")

        }else{
            //view group 2
            cinfirmTF.isHidden = true
            confirmCodeLB.isHidden = true
            confirmBtn.isHidden = true
            resendEmailBtn.isHidden = true
            //end view group 2
        }
        loginVC!.userisNotConfirmed = false

    }
}


extension SignUpViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
    }
}

