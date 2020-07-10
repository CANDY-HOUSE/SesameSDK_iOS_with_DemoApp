//
//  FriendsViewControllerCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public final class FriendsViewControllerCoordinator: Coordinator {
    public var childCoordinators: [String : Coordinator] = [:]
    public var parentCoordinator: Coordinator?
    public weak var presentedViewController: UIViewController?
    
    var navigationController: UINavigationController
    
    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    public func start() {
        guard let friendsViewController = UIStoryboard.viewControllers.friendsViewController else {
            return
        }
        let viewModel = FriendsViewModel()
        viewModel.delegate = self
        friendsViewController.viewModel = viewModel
        presentedViewController = friendsViewController
        navigationController.pushViewController(friendsViewController, animated: false)
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

extension FriendsViewControllerCoordinator: FriendsViewModelDelegate {
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
}
