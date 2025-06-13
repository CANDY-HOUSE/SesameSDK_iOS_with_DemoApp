//
//  SignUpViewController.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/11/15.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import AWSMobileClientXCF

protocol TouchViewDelegate: AnyObject {
    func touched()
}

class TouchView: UIView {
    weak var delegate: TouchViewDelegate?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        delegate?.touched()
    }
}

class SignUpViewController: CHBaseViewController, TouchViewDelegate {
    @IBOutlet weak var touchView: TouchView! {
        didSet {
            touchView.delegate = self
        }
    }

    var isLoggedIn = false
    var needResignIn = false
    var emailAddress: String!
    var dismissHandler: ((Bool)->Void)?
    var verification: ((String) -> Void)?
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var textFieldIndicator: UIView!
    @IBOutlet weak var loginButton: UIButton! {
        didSet {
            loginButton.addTarget(self, action: #selector(signUp), for: .touchUpInside)
            loginButton.layer.cornerRadius = 5.0
            loginButton.layer.masksToBounds = true
            loginButton.setBackgroundImage(UIImage.init(color: .sesame2Green), for: .normal)
            loginButton.setBackgroundImage(UIImage.init(color: .sesame2LightGray), for: .disabled)
            loginButton.setTitleColor(.white, for: .normal)
        }
    }
    @IBOutlet weak var contentTextField: UITextField! {
        didSet {
            contentTextField.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBarBackgroundColor = .white
        messageLabel.text = ""
        let font = UIFont.systemFont(ofSize: 60)
        let attributes = [
            NSAttributedString.Key.font : font,
            NSAttributedString.Key.baselineOffset : -1
        ] as [NSAttributedString.Key : Any]
        contentTextField.attributedPlaceholder = NSAttributedString(string: "your@email.com", attributes:attributes)
        contentTextField.text = ""
        contentTextField.keyboardType = .emailAddress
        contentTextField.autocorrectionType = .no
        contentTextField.font = font
        contentTextField.addTarget(self, action: #selector(contentTextFieldValueChanged(_:)), for: .editingChanged)
        loginButton.isEnabled = false
        loginButton.isHidden = false
        loginButton.setTitle("co.candyhouse.sesame2.sendSMS".localized, for: .normal)
        addKeyboardToolbar()
    }
    
    func touched() {
        contentTextField.resignFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isLoggedIn == false {
            guard AWSMobileClient.default().currentUserState != .signedOut else { return }
            AWSMobileClient.default().signOut()
        }
    }
    
    func addKeyboardToolbar()  {
        let viewForDoneButtonOnKeyboard = UIToolbar()
        viewForDoneButtonOnKeyboard.sizeToFit()
        
        let button = UIButton.init(type: .custom)
        button.setTitle(UserDefaults.standard.string(forKey: "email"), for: .normal)
        button.setTitleColor(.darkText, for: .normal)
        button.addTarget(self, action:#selector(doneBtnfromKeyboardClicked), for:.touchUpInside)
        button.frame = CGRect.init(x: 0, y: 0, width:UIScreen.main.bounds.width, height: 30) //CGRectMake(0, 0, 30, 30)
        
        let barButton = UIBarButtonItem.init(customView: button)
        viewForDoneButtonOnKeyboard.items = [barButton]
        
        contentTextField.inputAccessoryView = viewForDoneButtonOnKeyboard
    }
    
    @objc func viewTapped() {
        contentTextField.resignFirstResponder()
    }
    
    @objc func doneBtnfromKeyboardClicked(_ button: UIButton) {
        contentTextField.text = button.title(for: .normal)
        contentTextField.sendActions(for: .editingChanged)
    }

    @objc func dismissSelf() {
        dismissHandler?(self.isLoggedIn)
        navigationController?.popToRootViewController(animated: false)
    }
    
    @objc func signUp() {
        guard let emailStr = contentTextField.text, !emailStr.isEmpty else { return }
        contentTextField.resignFirstResponder()
        ViewHelper.showLoadingInView(view: view)
        let email = contentTextField.text!
        CHUserAPIManager.shared.signUpWithEmail(email) { (signUpResult, signUpError) in
            //            L.d("[註冊登入]signUpResult", signUpResult)
            // ex:SignUpResult(codeDeliveryDetails: nil, signUpConfirmationState: AWSMobileClientXCF.SignUpConfirmationState.confirmed)
            if signUpError == nil {
                executeOnMainThread {
                    self.navigateToSignIn()
                    ViewHelper.hideLoadingView(view: self.view)
                }
            } else if case .usernameExists(_) = signUpError as? AWSMobileClientError {
                executeOnMainThread {
                    self.navigateToSignIn()
                    ViewHelper.hideLoadingView(view: self.view)
                }
            } else if (signUpError as NSError?)?.code == -1009 {
                executeOnMainThread {
                    self.view.makeToast((signUpError! as NSError).errorDescription())
                    ViewHelper.hideLoadingView(view: self.view)
                }
            } else {
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
                    let errorMessage = (signUpError as? AWSMobileClientError)?.errorDescription()
                    self.view.makeToast(errorMessage ?? (signUpError! as NSError).errorDescription())
                }
            }
        }
    }
    
    func navigateToSignIn() {
        let email = contentTextField.text!
//            .applyingTransform(.fullwidthToHalfwidth, reverse: false)!.replacingOccurrences(of: "　", with: "").replacingOccurrences(of: " ", with: "")
        let verificationViewController = SignInViewController.instance(emailAddress: email) { isLoggedIn in
            executeOnMainThread {
                if isLoggedIn {
                    self.dismissHandler?(isLoggedIn)
                }
            }
        }
        self.navigationController?.pushViewController(verificationViewController, animated: true)
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        guard loginButton.isEnabled else { // 添加按下回车键时对输入内容的保护
            self.view.makeToast("co.candyhouse.sesame2.inputEMailWarn".localized)
            return true
        }
        signUp()
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = """
[a-zA-Z0-9\\+\\.\\_\\%\\-\\+]{1,256}\
\\@[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}\
(\\.[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25})+
"""
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: email)
    }
    
    @objc func contentTextFieldValueChanged(_ txtField: UITextField) {
        loginButton.isEnabled = isValidEmail(txtField.text ?? "")
    }
}

extension SignUpViewController {
    static func instance(_ dismissHandler: ((Bool)->Void)? = nil) -> SignUpViewController {
        let signUpViewController = SignUpViewController(nibName: "SignUpViewController", bundle: nil)
        signUpViewController.dismissHandler = dismissHandler
        signUpViewController.hidesBottomBarWhenPushed = true
        let navigationController = UINavigationController()
        navigationController.pushViewController(signUpViewController, animated: false)
        navigationController.modalPresentationStyle = .fullScreen
        return signUpViewController
    }
}
