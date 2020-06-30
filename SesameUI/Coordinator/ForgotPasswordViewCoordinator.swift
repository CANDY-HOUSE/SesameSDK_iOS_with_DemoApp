//
//  ForgotPasswordViewCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/23.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

public final class ForgotPasswordViewCoordinator: Coordinator {
    public var childCoordinators: [String : Coordinator] = [:]
    
    public weak var presentedViewController: UIViewController?
    public var presentingViewController: UIViewController
    
    private let email: String
    
    init(presentingViewController: UIViewController, email: String) {
        self.presentingViewController = presentingViewController
        self.email = email
    }
    
    public func start() {
        guard let forgotPasswordViewController = UIStoryboard.viewControllers.forgotPasswordViewController else {
            return
        }
        let viewModel = ForgotPasswordViewModel(email: email)
        viewModel.delegate = self
        forgotPasswordViewController.viewModel = viewModel
        presentingViewController.present(forgotPasswordViewController, animated: true, completion: nil)
        presentedViewController = forgotPasswordViewController
    }
}

extension ForgotPasswordViewCoordinator: ForgotPasswordViewModelDelegate {
    public func dismissTapped() {
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
}
