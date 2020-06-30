//
//  LockAngleSettingViewCoordinator.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/6/20.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public final class LockAngleSettingViewCoordinator: Coordinator {
    public var childCoordinators: [String : Coordinator] = [:]
    
    public weak var presentedViewController: UIViewController?
    
    private var navigationController: UINavigationController
    private var ssm: CHSesameBleInterface
    
    init(navigationController: UINavigationController, ssm: CHSesameBleInterface) {
        self.navigationController = navigationController
        self.ssm = ssm
    }
    
    public func start() {
        guard let lockAngleSettingViewController = UIStoryboard.viewControllers.lockAngleSettingViewController else {
            return
        }
        let viewModel = LockAngleSettingViewModel(ssm: ssm)
        lockAngleSettingViewController.viewModel = viewModel
        navigationController.pushViewController(lockAngleSettingViewController, animated: true)
    }
}
