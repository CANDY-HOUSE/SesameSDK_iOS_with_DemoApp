//
//  WebRegisterVC.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/25.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import WebKit
import AWSCognitoIdentityProvider
import AWSMobileClient

class SignUpViewController: CHBaseViewController , WKNavigationDelegate, WKUIDelegate {

    var viewModel: SignUpViewModel!
    
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
                    strongSelf.view.makeToast(error.errorDescription())
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
    }
    
    func confirmationCodeSendAlert() {
        let alertController = UIAlertController(title: viewModel.confirmationCodeSendAlertTitle,
                                                message: viewModel.confirmationCodeSendAlertMessage,
            preferredStyle: .alert)
        let okAction = UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.OK".localized,
                                     style: .default,
                                     handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func back(_ sender: Any) {
        viewModel.backTapped()
    }

    @IBAction func signup(_ sender: Any) {
        self.view.endEditing(true)
        
        viewModel.signUpTapped(password: passwordTextField.text!,
                               email: emailTextField.text!.toMail(),
                               givenName: givenNameTextField.text!,
                               familyName: familyNameTextField.text!)
    }

    @IBAction func confirmuser(_ sender: Any) {
        viewModel.confirmUserTapped(email: emailTextField.text!.toMail(),
                                    confirmationCode: confirmationCodeTextField.text!)
    }
    
    @IBAction func reSendEmail(_ sender: Any) {
        viewModel.reSendEmailTapped(email: emailTextField.text!.toMail())
    }
}

extension SignUpViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
    }
}

