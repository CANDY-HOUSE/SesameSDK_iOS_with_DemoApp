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
    public var parentCoordinator: Coordinator?
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
    
    public func childCoordinatorDismissed(_ coordinator: Coordinator, userInfo: [String: Any]) {
        if let _ = coordinator as? RegisterDeviceListViewCoordinator,
            let dismissReason = userInfo[RegisterDeviceListViewCoordinator.DismissReason.key] as? RegisterDeviceListViewCoordinator.DismissReason,
            dismissReason == RegisterDeviceListViewCoordinator.DismissReason.registerSucceeded {
            presentedViewController?.viewWillAppear(true)
        } else if let _ = coordinator as? ScanViewCoordinator,
            let dismissReason = userInfo[ScanViewCoordinator.DismissReason.key] as? ScanViewCoordinator.DismissReason,
            dismissReason == ScanViewCoordinator.DismissReason.registerSucceeded {
            presentedViewController?.viewWillAppear(true)
        }
    }
}

extension MeViewCoordinator: MeViewModelDelegate {
    public func showMyQRCodeTappe() {
        // TODO: Implement share qr code navigation
    }
    
    public func scanViewTapped() {
        let scanViewCoordinator = ScanViewCoordinator(navigationController: navigationController)
        scanViewCoordinator.parentCoordinator = self
        scanViewCoordinator.start()
    }
    
    public func newSesameTapped() {
        let registerDeviceViewCoordinator = RegisterDeviceListViewCoordinator(navigationController: navigationController)
        registerDeviceViewCoordinator.parentCoordinator = self
        registerDeviceViewCoordinator.start()
    }
    
    public func loginRegisterTapped() {
        let loginViewController = LogInViewCoordinator(navigationController: navigationController)
        loginViewController.start()
    }
}
