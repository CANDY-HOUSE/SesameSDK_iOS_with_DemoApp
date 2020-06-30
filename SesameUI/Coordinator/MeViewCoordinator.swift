//
//  MeViewCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

public final class MeViewCoordinator: Coordinator {
    public var childCoordinators: [String : Coordinator] = [:]
    
    public var presentedViewController: UIViewController?
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    public func start() {
        guard let meViewController = UIStoryboard.viewControllers.meViewController else {
            return
        }
        let viewModel = MeViewModel()
        viewModel.delegate = self
        meViewController.viewModel = viewModel
        presentedViewController = meViewController
        navigationController.pushViewController(meViewController, animated: false)
    }
}

extension MeViewCoordinator: MeViewModelDelegate {
    public func showMyQRCodeTappe() {
        // TODO: Implement share qr code navigation
    }
    
    public func scanViewTapped() {
        let scanViewCoordinator = ScanViewCoordinator(navigationController: navigationController)
        scanViewCoordinator.start()
    }
    
    public func newSesameTapped() {
        let registerDeviceViewCoordinator = RegisterDeviceListViewCoordinator(navigationController: navigationController)
        registerDeviceViewCoordinator.start()
    }
    
    public func loginRegisterTapped() {
        let loginViewController = LogInViewCoordinator(navigationController: navigationController)
        loginViewController.start()
    }
}
