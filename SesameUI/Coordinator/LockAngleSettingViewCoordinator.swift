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
    public var parentCoordinator: Coordinator?
    public weak var presentedViewController: UIViewController?
    
    private var navigationController: UINavigationController
    private var sesame2: CHSesame2
    
    init(navigationController: UINavigationController, sesame2: CHSesame2) {
        self.navigationController = navigationController
        self.sesame2 = sesame2
    }
    
    public func start() {
        guard let lockAngleSettingViewController = UIStoryboard.viewControllers.lockAngleSettingViewController else {
            return
        }
        let viewModel = LockAngleSettingViewModel(sesame2: sesame2)
        lockAngleSettingViewController.viewModel = viewModel
        navigationController.pushViewController(lockAngleSettingViewController, animated: true)
    }
}
