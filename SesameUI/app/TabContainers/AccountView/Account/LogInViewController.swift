//
//  LoginViewController.swift
//  sesame-sdk-test-app
//
//  Created by Yiling on 2019/08/05.
//  Copyright © 2019 Cerberus. All rights reserved.
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
            case .received:
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
                            strongSelf.view.makeToast(ErrorMessage.descriptionFromError(error: error))
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
                                          fillColor: UIColor.sesameLightGray)
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

//        AWSMobileClient.default().signIn(username: username,
//                                         password: password,
//                                         validationData:nil) { result, error in
//            if let error = error  {
//                if let awsError = error as? AWSMobileClientError {
//                    switch awsError {
//                    case .userNotConfirmed(message: _):
//                        DispatchQueue.main.async {
//                            self.userisNotConfirm = true
//                            self.didPressSignupOrForgotPassword("")
//                            ViewHelper.hideLoadingView(view: self.view)
//                        }
//                    default:
//                        DispatchQueue.main.async {
//                            self.view.makeToast(ErrorMessage.descriptionFromError(error: error))
//                            ViewHelper.hideLoadingView(view: self.view)
//                        }
//                    }
//                }
//            } else {
//                L.d("帳號密碼登入成功")
//
//
//                DispatchQueue.main.async {
//                    CHUIKeychainManager.shared.setUsername(username,
//                                                           password: password)
//                    self.userisNotConfirm = false
//                    self.dismissSelf()
//                    ViewHelper.hideLoadingView(view: self.view)
//                    self.checkNameAndBindCHServer()
//                }
//            }
//        }
    }
    
//    func checkNameAndBindCHServer() {
//        AWSMobileClient.default().getUserAttributes { userAttributes, error in
//
//            if let error = error {
//                L.d(ErrorMessage.descriptionFromError(error: error))
//            } else if let userAttributes = userAttributes {
//                do {
//                    let user = try User.userFromAttributes(userAttributes)
//                    CHAccountManager.shared.updateMyProfile(
//                        first_name:user.givenName,
//                        last_name:user.familyName
//                    ) { result in
//                        switch result {
//                        case .success(let candyUUID):
//                            L.d(candyUUID.data as Any)
//                        case .failure(let error):
//                            L.d(ErrorMessage.descriptionFromError(error: error))
//                        }
//                    }
////                    CHAccountManager.shared.getMyProfile(){profile in
////                        L.d(profile.nickname)
////                        L.d(profile.getCandyUUID())
////                    }
//                } catch {
//                    // TODO: Error Hnadleing
//                    L.d(ErrorMessage.descriptionFromError(error: error))
//                }
//            } else {
//                L.d("All Null")
//            }
//        }
//    }
    
    @IBAction func forgetPassword(_ sender: Any) {
//        self.performSegue(withIdentifier:  "forget", sender: nil)
        viewModel.forgotPasswordTapped(email: (userName?.text)!.toMail())
    }
    @IBAction func didPressSignupOrForgotPassword(_ sender: Any) {
//        self.performSegue(withIdentifier:  "sign", sender: nil)
        viewModel.signUpTapped(email: (userName?.text)!.toMail(),
                               password: (self.password?.text!)!)
    }
    
    @objc func dismissSelf() {
//        self.dismiss(animated: true, completion:nil)
        viewModel.dismissTapped()
    }
}

extension LogInViewController{

    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let controller = segue.destination as? SignUpViewController {
//            controller.loginVC = self
//        }
//        if let controller = segue.destination as? ForgotPasswordViewController {
//            controller.loginVC = self
//        }
    }
}
