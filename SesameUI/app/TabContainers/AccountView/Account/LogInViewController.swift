//
//  LoginViewController.swift
//  sesame-sdk-test-app
//
//  Created by Yiling on 2019/08/05.
//  Copyright © 2019 CandyHouse. All rights reserved.
//
import AWSAPIGateway
import UIKit
import SesameSDK
import AWSMobileClient

extension LogInViewController:UITextFieldDelegate{
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
    }
}

public class LogInViewController: CHBaseViewController {
    var viewModel: LogInViewModel!
    
    var tabVC:GeneralTabViewController?
    @IBOutlet weak var subLogInImage: UIImageView!
    @IBOutlet weak var logInImage: UIImageView!
    @IBOutlet weak var quickLoginView: UIScrollView!

    @IBOutlet weak var userName: UITextField! {
        didSet {
            userName.text = UserDefaults.standard.string(forKey: "email")
        }
    }
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var passwordLabel: UILabel!

    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var logInButton: UIButton!

    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBAction func testJerming(_ sender: Any) {
        userName.text = "tse+31@candyhouse.co"
        password.text = "111111"
        loginDidPress("")
    }

    @IBAction func testTse(_ sender: Any) {
        userName.text = "tse@candyhouse.co"
        password.text = "111111"
        loginDidPress("")
    }

    @IBAction func testtsem(_ sender: Any) {
        userName.text = "Tse@candy house.co "
        password.text = "222222"
        loginDidPress("")
    }

    @IBAction func testhci(_ sender: Any) {
        userName.text = "tse+10@candyhouse.co"
        password.text = "111111"
        loginDidPress("")
    }

    @IBAction func testpeter(_ sender: Any) {
        userName.text = "peter.su+1@candyhouse.co"
        password.text = "111111"
        loginDidPress("")
    }
    @IBAction func testChihiro(_ sender: Any) {
        userName.text = "tse+5@candyhouse.co"
        password.text = "111111"
        loginDidPress("")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(viewModel != nil, "LogInViewModel should not be nil")
        
        viewModel.statusUpdated = { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            switch status {
            case .loading:
                break
            case .update:
                break
            case .finished(let result):
                switch result {
                case .success(_):
                    executeOnMainThread {
                        strongSelf.dismissSelf()
                    }
                case .failure(let error):
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: strongSelf.view)
                        if strongSelf.viewModel.signUpType == .unconfirmedUser {
                            strongSelf.didPressSignupOrForgotPassword("")
                        } else {
                            strongSelf.view.makeToast(error.errorDescription())
                        }
                    }
                }
            }
        }
        
        
        #if DEBUG
        quickLoginView.isHidden = false
        #else
        quickLoginView.isHidden = true
        #endif
        
        userName.delegate = self
        password.delegate = self
        
        logInImage.image = UIImage.SVGImage(named: viewModel.logInImage)
        subLogInImage.image = UIImage.SVGImage(named: viewModel.subLogInImage)

        logInButton.setTitle(viewModel.logInButtonTitle, for: .normal)
        nameLabel.text = viewModel.nameLabelText
        passwordLabel.text = viewModel.passwordLabelText
        signUpButton.setTitle(viewModel.signUpButtonTitle, for: .normal)
        forgotPasswordButton.setTitle(viewModel.forgotPasswordButtonTitle, for: .normal)
        
        let versionLabel = VersionLabel()
        self.view.addSubview(versionLabel)
        let constraints = [
            versionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            versionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            versionLabel.widthAnchor.constraint(equalTo: view.widthAnchor),
            versionLabel.heightAnchor.constraint(equalToConstant: 40)
        ]
        NSLayoutConstraint.activate(constraints)

        let closeImage = UIImage.SVGImage(named: viewModel.closeImage,
                                          fillColor: UIColor.sesame2LightGray)
        let closeButton = UIButton(type: .custom)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(closeImage, for: .normal)
        closeButton.addTarget(self, action: #selector(LogInViewController.dismissSelf),
                              for: .touchUpInside)

        view.addSubview(closeButton)
        let closeButtonConstraints = [
            closeButton.leftAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leftAnchor, constant: 10),
            closeButton.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ]
        NSLayoutConstraint.activate(closeButtonConstraints)
    }
    
    @IBAction func loginDidPress(_ sender: Any) {
        self.view.endEditing(true)
        ViewHelper.showLoadingInView(view: self.view)
        let username = (userName?.text)!.toMail()
        let password = (self.password?.text!)!

        L.d("🦠", username, password)
        
        viewModel.logInDidPressed(userName: username, password: password)
    }
    
    @IBAction func forgetPassword(_ sender: Any) {
        viewModel.forgotPasswordTapped(email: (userName?.text)!.toMail())
    }
    
    @IBAction func didPressSignupOrForgotPassword(_ sender: Any) {
        viewModel.signUpTapped(email: (userName?.text)!.toMail(),
                               password: (self.password?.text!)!)
    }
    
    @objc func dismissSelf() {
        viewModel.dismissTapped()
    }
}
