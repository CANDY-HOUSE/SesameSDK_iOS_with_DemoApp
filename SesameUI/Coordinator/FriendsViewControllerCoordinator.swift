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
}

extension FriendsViewControllerCoordinator: FriendsViewModelDelegate {
    public func scanViewTapped() {
        let scanViewCoordinator = ScanViewCoordinator(navigationController: navigationController)
        scanViewCoordinator.start()
    }
    
    public func newSesameTapped() {
        let registerDeviceViewCoordinator = RegisterDeviceListViewCoordinator(navigationController: navigationController)
        registerDeviceViewCoordinator.start()
    }
}
