//
//  SignUpViewController.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/12/7.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import UIKit
import SesameSDK
import AWSCognitoIdentityProvider
import AWSMobileClient

class ForgotPasswordViewController: CHBaseViewController {
//    var loginVC:LogInViewController? = nil
    
    var viewModel: ForgotPasswordViewModel!

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var resendEmailButton: UIButton!
    
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var confirmationCodeLabel: UILabel!
    @IBOutlet weak var confirmationCodeTextField: UITextField!
    
    @IBOutlet weak var newPasswordLabel: UILabel!
    @IBOutlet weak var newPasswordTextField: UITextField!

    @IBOutlet weak var confirmationButton: UIButton!

    @IBAction func back(_ sender: Any) {
        viewModel.backTapped()
    }
    
    @IBAction func resendEmail(_ sender: Any) {

        self.view.endEditing(true)
        
        AWSMobileClient
            .default()
            .forgotPassword(username: emailTextField.text!.toMail()) { forgotPasswordResult, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.view.makeToast(error.errorDescription())
                    } else if let result = forgotPasswordResult {
                        let alertController = UIAlertController(title: "Code Sent",
                                                                message: "Code sent to \(result.codeDeliveryDetails?.destination ?? "no message")",
                            preferredStyle: .alert)
                        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                        alertController.addAction(okAction)
                        self.present(alertController, animated: true, completion: nil)

                        // view group1
                        self.confirmationCodeTextField.isHidden = false
                        self.confirmationCodeLabel.isHidden = false
                        self.newPasswordTextField.isHidden = false
                        self.newPasswordLabel.isHidden = false
                        self.confirmationButton.isHidden = false
                        // view group1 end
                    } else {
                        self.view.makeToast("Unknow error.")
                    }
                }
        }
    }
    
    @IBAction func confirm(_ sender: Any) {
        self.view.endEditing(true)
        
//        AWSMobileClient
//            .default()
//            .confirmForgotPassword(username: emailTextField.text!.toMail(),
//                                   newPassword: self.newPasswordTextField.text!,
//                                   confirmationCode: self.confirmationCodeTextField.text!)
//            { forgotPasswordResult, error in
//                DispatchQueue.main.async {
//                    if let error = error {
//                        self.view.makeToast(ErrorMessage.descriptionFromError(error: error))
//                    } else {
//                        DispatchQueue.main.async {
//                            self.loginVC?.userName.text = self.emailTextField.text!.toMail()
//                            self.loginVC?.password.text = self.newPasswordTextField.text
//                            self.dismiss(animated: true, completion:nil)
//                            self.view.makeToast("change sucess".localStr)
//                        }
//                        let _ = self.navigationController?.popToRootViewController(animated: true)
//                    }
//                }
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(viewModel != nil, "ForgotPasswordViewModel should not be nil")
        
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
                switch result {
                case .success(let signUpResult):
                    if let signUpResult = signUpResult as? ForgotPasswordResult {
                        
                        switch signUpResult.forgotPasswordState {
                        case .done:
                            strongSelf.viewModel.backTapped()
                        case .confirmationCodeSent:
                            strongSelf.confirmationCodeSendAlert()
                            strongSelf.refreshUI()
                        }
                    }
                case .failure(let error):
                    strongSelf.view.makeToast(error.errorDescription())
                }
            }
        }
        
        backButton.setImage( UIImage.SVGImage(named: viewModel.backButtonImage), for: .normal)
        emailTextField.text = viewModel.email
        newPasswordTextField.text = viewModel.password
        
        emailTextField.delegate = self
        newPasswordTextField.delegate = self
        confirmationCodeTextField.delegate = self

        emailLabel.text = viewModel.emailLabelText
        confirmationCodeLabel.text = viewModel.confirmationCodeLabelText
        newPasswordLabel.text = viewModel.newPasswordLabelText

        confirmationButton.setTitle(viewModel.confirmationButtonTitle, for: .normal)
        resendEmailButton.setTitle(viewModel.resendEmailButtonTitle, for: .normal)

        refreshUI()
    }
    
    func confirmationCodeSendAlert() {
        let alertController = UIAlertController(title: viewModel.confirmationCodeAlertTitle,
                                                message: viewModel.confirmationCodeSendAlertMessage,
            preferredStyle: .alert)
        let okAction = UIAlertAction(title: viewModel.confirmationCodeActionTitle,
                                     style: .default,
                                     handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func refreshUI() {
        confirmationCodeTextField.isHidden = viewModel.hideContent()
        confirmationCodeLabel.isHidden = viewModel.hideContent()
        newPasswordTextField.isHidden = viewModel.hideContent()
        newPasswordLabel.isHidden = viewModel.hideContent()
        confirmationButton.isHidden = viewModel.hideContent()
    }
}
extension ForgotPasswordViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
    }
}

