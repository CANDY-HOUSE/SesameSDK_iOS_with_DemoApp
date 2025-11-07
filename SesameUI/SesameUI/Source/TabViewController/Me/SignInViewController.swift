//
//  SignInViewController.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/02/04.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import AWSMobileClientXCF

class SignInViewController: CHBaseViewController, TouchViewDelegate {
    
    @IBOutlet weak var touchView: TouchView! {
        didSet {
            touchView.delegate = self
        }
    }
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var textFieldIndicator: UIView!
    
    @IBOutlet weak var contentTextField: UITextField! {
        didSet {
            contentTextField.delegate = self
        }
    }
    
    @IBOutlet weak var verifySMSButton: UIButton! {
        didSet {
            verifySMSButton.addTarget(self, action: #selector(verifySMS), for: .touchUpInside)
            verifySMSButton.layer.cornerRadius = 5.0
            verifySMSButton.layer.masksToBounds = true
            verifySMSButton.backgroundColor = .sesame2Green
            verifySMSButton.setTitleColor(.white, for: .normal)
        }
    }
    
    var dismissHandler: ((Bool)->Void)?
    var emailAddress: String = ""
    var signInState: SignInState?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBarBackgroundColor = .white
     
        let font = UIFont.systemFont(ofSize: 120)
        messageLabel.text = "co.candyhouse.sesame2.VerificationCode".localized
        contentTextField.isHidden = false
        textFieldIndicator.isHidden = false
        contentTextField.text = ""
        contentTextField.keyboardType = .decimalPad
        contentTextField.autocorrectionType = .no
        contentTextField.becomeFirstResponder()
        contentTextField.textAlignment = .center
        contentTextField.font = font
        contentTextField.attributedPlaceholder = NSAttributedString(string: "1234", attributes:[NSAttributedString.Key.font : font])
        verifySMSButton.isHidden = true
        CHUserAPIManager.shared.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        CHUserAPIManager.shared.signOut { [self] in
            CHUserAPIManager.shared.signInWithEmail(emailAddress)
        }
    }

    func touched() {
        contentTextField.resignFirstResponder()
    }
    
    @objc func dismissSelf() {
        if signInState != .signedIn {
            dismissHandler?(false)
            navigationController?.popViewController(animated: true)
        } else {
            dismissHandler?(true)
            navigationController?.popToRootViewController(animated: false)
        }
    }
}

extension SignInViewController: UITextFieldDelegate { // [joi todo]UI寫法應該要簡化
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        verifySMS() 
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if range.location <= 3, range.length == 0 { // Add
            if range.location == 3 {
                DispatchQueue.main.async { // note：此处不可使用executeOnMainThread： 需要等待下一个主线程周期，以便能拿到textField中的四个数据
                    ViewHelper.showLoadingInView(view: self.view)
                    textField.resignFirstResponder()
                    self.verifySMS()
                }
            }
            return true
        } else if range.length == 1 { // Delete
            return true
        } else {
            return false
        }
    }
    
    @objc func verifySMS() {
        view.hideAllToasts()
        CHUserAPIManager.shared.verifySMS(self.contentTextField.text!, ofEmail: emailAddress)
    }
}

// MARK: - CHUserManagerLoginDelegate
extension SignInViewController: CHUserManagerSignInDelegate {
    func signInStatusDidChanged(_ status: SignInState) {
        executeOnMainThread {
            ViewHelper.hideLoadingView(view: self.view)
            self.signInState = status
        }
    }
    
    func signInCompleteHandler(_ result: Result<NSNull, Error>) {
        executeOnMainThread {
            if case .failure(let error) = result {
                if case AWSMobileClientError.notAuthorized(message: "Incorrect username or password.") = error {
                    self.view.makeToast(NSError.verificationCodeError.errorDescription())
                } else if (error as NSError).code == -1009 {
                    self.view.makeToast((error as NSError).errorDescription())
                } else {
                    self.view.makeToast(NSError.signInFailedError.errorDescription())
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                self.dismissSelf()
            }
            ViewHelper.hideLoadingView(view: self.view)
        }
    }
    
    func getNickname(_ result: @escaping (Result<NSNull, Error>) -> Void) {
        CHUserAPIManager.shared.getNickname { getResult in
            if case let .success(nickname) = getResult {
                if let nickname = nickname {
                    Sesame2Store.shared.setHistoryTag(nickname)
                    result(.success(NSNull()))
                } else {
                    CHUserAPIManager.shared.updateNickname("User") { _ in
                        Sesame2Store.shared.setHistoryTag("User")
                        result(.success(NSNull()))
                    }
                }
            } else if case let .failure(error) = getResult {
                result(.failure(error))
            }
        }
    }
}

extension SignInViewController {
    static func instance(emailAddress: String, _ dismissHandler: ((Bool)->Void)? = nil) -> SignInViewController {
        let smsViewController = SignInViewController(nibName: "SignInViewController", bundle: nil)
        smsViewController.dismissHandler = dismissHandler
        smsViewController.hidesBottomBarWhenPushed = true
        smsViewController.emailAddress = emailAddress
        let navigationController = UINavigationController()
        navigationController.pushViewController(smsViewController, animated: false)
        navigationController.modalPresentationStyle = .fullScreen
        return smsViewController
    }
}
