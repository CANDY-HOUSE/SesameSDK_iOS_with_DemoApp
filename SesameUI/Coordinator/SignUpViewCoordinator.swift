//
//  SignUpViewCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/23.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

public final class SignUpViewCoordinator: Coordinator {
    public var childCoordinators: [String : Coordinator] = [:]
    
    public weak var presentedViewController: UIViewController?
    public var presentingViewController: UIViewController
    
    private let email: String
    private let password: String
    private let signUpType: SignUpViewModel.SignUpType
    
    init(presentingViewController: UIViewController,
         email: String,
         password: String,
         signUpType: SignUpViewModel.SignUpType) {
        self.presentingViewController = presentingViewController
        self.email = email
        self.password = password
        self.signUpType = signUpType
    }
    
    public func start() {
        guard let signUpViewController = UIStoryboard.viewControllers.signUpViewController else {
            return
        }
        let viewModel = SignUpViewModel(email: email,
                                        password: password,
                                        signUpType: signUpType)
        viewModel.delegate = self
        signUpViewController.viewModel = viewModel
        presentedViewController = signUpViewController
        presentingViewController.present(signUpViewController, animated: true, completion: nil)
    }
}

extension SignUpViewCoordinator: SignUpViewModelDelegate {
    public func backTapped() {
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
}
