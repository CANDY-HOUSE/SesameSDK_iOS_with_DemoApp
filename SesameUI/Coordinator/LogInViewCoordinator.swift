//
//  LoginViewCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/23.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

public final class LogInViewCoordinator: Coordinator {
    public var childCoordinators: [String : Coordinator] = [:]
    public var parentCoordinator: Coordinator?
    public weak var presentedViewController: UIViewController?
    public var navigationController: UINavigationController
    
    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    public func start() {
        guard let logInViewController = UIStoryboard.viewControllers.loginViewController else {
            return
        }
        let viewModel = LogInViewModel()
        viewModel.delegate = self
        logInViewController.viewModel = viewModel
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.present(logInViewController, animated: true, completion: nil)
        presentedViewController = logInViewController
    }
}

extension LogInViewCoordinator: LogInViewModelDelegate {
    public func forgotPasswordTapped(email: String) {
        let forgotPasswordCoordinator = ForgotPasswordViewCoordinator(presentingViewController: presentedViewController!,
                                                                      email: email)
        forgotPasswordCoordinator.start()
    }
    
    public func signUpTapped(email: String, password: String, signUpType: SignUpViewModel.SignUpType) {
        let signUpCoordinator = SignUpViewCoordinator(presentingViewController: presentedViewController!,
                                                      email: email,
                                                      password: password,
                                                      signUpType: signUpType)
        signUpCoordinator.start()
        
    }
    
    public func dismissTapped() {
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
}
