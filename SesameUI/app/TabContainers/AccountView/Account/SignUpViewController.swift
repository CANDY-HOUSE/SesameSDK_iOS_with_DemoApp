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

class SignUpViewController: CHBaseViewController , WKNavigationDelegate, WKUIDelegate {

//    var loginVC:LogInViewController? = nil
    var viewModel: SignUpViewModel!
    
    @IBAction func back(_ sender: Any) {
        viewModel.backTapped()
    }

    @IBAction func signup(_ sender: Any) {
        self.view.endEditing(true)
        
        viewModel.signUpTapped(password: passwordTextField.text!,
                               email: emailTextField.text!.toMail(),
                               givenName: givenNameTextField.text!,
                               familyName: familyNameTextField.text!)
        
//        let userAttributes: [String: String] = [
//            "email": emailTF.text!.toMail(),
//            "given_name": givenNameTF.text!,
//            "family_name": userTF.text!
//        ]
        
//        AWSMobileClient
//            .default()
//            .signUp(username: emailTF.text!.toMail(),
//                    password: passwordTF.text!,
//                    userAttributes: userAttributes) { result, error in
//                        DispatchQueue.main.async {
//                            if let error = error as? AWSMobileClientError {
//                                // TODO: Error Handle
//                                L.d(ErrorMessage.descriptionFromError(error: error))
//                                self.view.makeToast(ErrorMessage.descriptionFromError(error: error))
//                            } else if let result = result {
//                                switch result.signUpConfirmationState {
//                                case .confirmed:
//                                    self.view.makeToast("confirmed")
//                                case .unconfirmed:
//                                    self.view.makeToast("unconfirmed")
//
//                                    //view group 1
//                                    self.userTF.isEnabled = false
//                                    self.givenNameTF.isEnabled = false
//                                    self.passwordTF.isEnabled = false
//                                    self.emailTF.isEnabled = false
//                                    self.signupBtn.isEnabled = false
//                                    self.signupBtn.backgroundColor = UIColor.lightGray
//                                    self.signupBtn.alpha = 0.6
//                                    //end view group 1
//
//                                    //view group 2
//                                    self.cinfirmTF.isHidden = false // todo test
//                                    self.confirmCodeLB.isHidden = false
//                                    self.confirmBtn.isHidden = false
//                                    self.resendEmailBtn.isHidden = false
//                                    //end view group 2
//
//                                    let alertController = UIAlertController(title: "Code Sent",
//                                                                            message: "Code sent to \(result.codeDeliveryDetails?.destination ?? "no message")",
//                                        preferredStyle: .alert)
//                                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
//                                    alertController.addAction(okAction)
//                                    self.present(alertController, animated: true, completion: nil)
//
//                                case .unknown:
//                                    self.view.makeToast("unknown")
//                                }
//                            } else {
//                                self.view.makeToast("Unknow error")
//                            }
//                        }
//        }
    }

    @IBAction func confirmuser(_ sender: Any) {
        viewModel.confirmUserTapped(email: emailTextField.text!.toMail(),
                                    confirmationCode: confirmationCodeTextField.text!)
//        AWSMobileClient
//            .default()
//            .confirmSignUp(username: emailTF.text!.toMail(),
//                           confirmationCode: self.cinfirmTF.text!) { signUpResult, error in
//                            DispatchQueue.main.async {
//                                if let error = error {
//                                    self.view.makeToast(ErrorMessage.descriptionFromError(error: error))
//                                } else {
//                                    self.loginVC?.userName.text = self.emailTF.text!.toMail()
//                                    self.loginVC?.password.text = self.passwordTF.text
//                                    self.dismiss(animated: true, completion:nil)
//                                }
//                            }
//        }
    }
    
    @IBAction func reSendEmail(_ sender: Any) {
        viewModel.reSendEmailTapped(email: emailTextField.text!.toMail())
    }
    
    @IBOutlet weak var familyNameLabel: UILabel!
    @IBOutlet weak var familyNameTextField: UITextField!
    
    @IBOutlet weak var givenNameLabel: UILabel!
    @IBOutlet weak var givenNameTextField: UITextField!
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBOutlet weak var confirmationCodeLabel: UILabel!
    @IBOutlet weak var confirmationCodeTextField: UITextField!
    
    @IBOutlet weak var confirmationButton: UIButton!
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var resendEmailButton: UIButton!

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
        
        assert(viewModel != nil, "SignUpViewModel should not be nil")
        L.d("viewDidLoad")
        
        viewModel.statusUpdated = { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            switch status {
            case .loading:
                break
            case .received:
                break
            case .finished(let result):
                // TODO: Eliminate logic from UI
                switch result {
                case .success(let signUpResult):
                    if let signUpResult = signUpResult as? SignUpResult,
                        let deliveryType = signUpResult.codeDeliveryDetails {
                        switch deliveryType.deliveryMedium {
                        case .email:
                            executeOnMainThread {
                                strongSelf.confirmationCodeSendAlert()
                                strongSelf.refreshUI()
                            }
                        default:
                            switch signUpResult.signUpConfirmationState {
                            case .confirmed:
                                executeOnMainThread {
                                    strongSelf.viewModel.backTapped()
                                }
                            default:
                                executeOnMainThread {
                                    strongSelf.refreshUI()
                                }
                            }
                        }
                    }
                case .failure(let error):
                    strongSelf.view.makeToast(ErrorMessage.descriptionFromError(error: error))
                }
            }
        }
        
        familyNameTextField.delegate = self
        givenNameTextField.delegate = self
        passwordTextField.delegate = self
        emailTextField.delegate = self
        confirmationCodeTextField.delegate = self
        
        refreshUI()
    }
    
    func refreshUI() {
        backButton.setImage( UIImage.SVGImage(named: viewModel.backButtonImage), for: .normal)
        
        emailLabel.text = viewModel.mailLabelText
        familyNameLabel.text = viewModel.lastNameLabelText
        givenNameLabel.text = viewModel.firstNameLabelText
        passwordLabel.text = viewModel.passwordLabelText
        confirmationCodeLabel.text = viewModel.confirmationCodeLabelText
        signUpButton.setTitle(viewModel.signUpButtonTitle, for: .normal)
        confirmationButton.setTitle(viewModel.confirmationButtonTtitle, for: .normal)
        resendEmailButton.setTitle(viewModel.resendEmailButtonTitle, for: .normal)

        emailTextField.text = viewModel.email
        passwordTextField.text = viewModel.password

        givenNameTextField.isHidden = viewModel.hideNewUserContent()
        familyNameTextField.isHidden = viewModel.hideNewUserContent()
        signUpButton.isHidden = viewModel.hideNewUserContent()
        familyNameLabel.isHidden = viewModel.hideNewUserContent()
        givenNameLabel.isHidden = viewModel.hideNewUserContent()
        passwordTextField.isHidden = viewModel.hideNewUserContent()
        passwordLabel.isHidden = viewModel.hideNewUserContent()
        
        confirmationCodeTextField.isHidden = viewModel.hideUnconfirmedUserContent()
        confirmationCodeLabel.isHidden = viewModel.hideUnconfirmedUserContent()
        confirmationButton.isHidden = viewModel.hideUnconfirmedUserContent()
        resendEmailButton.isHidden = viewModel.hideUnconfirmedUserContent()
        
        if viewModel.signUpType == .unconfirmedUser {
            reSendEmail("")
        }
        
//        loginVC!.userisNotConfirmed = false
    }
    
    func confirmationCodeSendAlert() {
        let alertController = UIAlertController(title: viewModel.confirmationCodeSendAlertTitle,
                                                message: viewModel.confirmationCodeSendAlertMessage,
            preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

extension SignUpViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
    }
}

