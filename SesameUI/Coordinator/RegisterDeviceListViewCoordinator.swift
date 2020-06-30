//
//  RegisterDeviceListViewCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public final class RegisterDeviceListViewCoordinator: Coordinator {
    public var childCoordinators: [String : Coordinator] = [:]
    
    public weak var presentedViewController: UIViewController?
    
    private var navigationController: UINavigationController
    
    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    public func start() {
        guard let registerViewController = UIStoryboard.viewControllers.registerDeviceListVC else {
            return
        }
        let viewModel = RegisterDeviceListViewModel()
        viewModel.delegate = self
        registerViewController.viewModel = viewModel
        presentedViewController = registerViewController
        navigationController.present(registerViewController, animated: true, completion: nil)
    }
    
    deinit {
        L.d("RegisterDeviceListViewCoordinator deinit")
    }
}

extension RegisterDeviceListViewCoordinator: RegisterDeviceListViewModelDelegate {
    public func registerSSMSucceed() {
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
}
