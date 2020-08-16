//
//  RegisterWifiModule2ViewCoordinator.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

public final class RegisterWifiModule2ViewCoordinator: Coordinator {
    public enum DismissReason: String {
        static let key = "DismissReason"
        case cancel, registerSucceeded
    }
    
    public var childCoordinators: [String : Coordinator] = [:]
    
    public var parentCoordinator: Coordinator?
    
    public var presentedViewController: UIViewController?
    
    private var navigationController: UINavigationController
    
    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    public func start() {
//        guard let registerWifiModule2ViewController = UIStoryboard.viewControllers.registerWifiModule2TableViewController else {
//            return
//        }
//        let viewModel = RegisterWifiModule2ViewModel()
//        viewModel.delegate = self
//        registerWifiModule2ViewController.viewModel = viewModel
//        presentedViewController = registerWifiModule2ViewController
//        navigationController.present(registerWifiModule2ViewController, animated: true, completion: nil)
    }
}

extension RegisterWifiModule2ViewCoordinator: RegisterWifiModule2ViewModelDelegate {
    public func registerWifiModule2Succeed() {
        
    }
}
