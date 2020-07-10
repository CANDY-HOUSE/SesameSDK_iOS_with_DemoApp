//
//  SSM2SettingViewControllerCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public final class SSM2SettingViewControllerCoordinator: Coordinator {
    public var childCoordinators: [String : Coordinator] = [:]
    public var parentCoordinator: Coordinator?
    public weak var presentedViewController: UIViewController?
    var navigationController: UINavigationController
    private var ssm: CHSesame2
    
    public init(navigationController: UINavigationController, ssm: CHSesame2) {
        self.navigationController = navigationController
        self.ssm = ssm
    }
    
    public func start() {
        guard let ssm2SettingViewController = UIStoryboard.viewControllers.ssm2SettingVC else {
            return
        }
        
        let viewModel = SSM2SettingViewModel(ssm: ssm)
        viewModel.delegate = self
        ssm2SettingViewController.viewModel = viewModel
        presentedViewController = ssm2SettingViewController
        navigationController.pushViewController(ssm2SettingViewController, animated: true)
    }
    
    deinit {
        L.d("SSM2SettingViewControllerCoordinator deinit")
    }
}

extension SSM2SettingViewControllerCoordinator: SSM2SettingViewModelDelegate {
    public func setAngleForSSM(_ ssm: CHSesame2) {
        let lockAngleSettingViewCoordinator = LockAngleSettingViewCoordinator(navigationController: navigationController, ssm: ssm)
        lockAngleSettingViewCoordinator.start()
    }
    
    public func shareSSMTapped(_ ssm: CHSesame2) {
        let myQRCodeViewCoordinator = MyQRCodeViewCoordinator(navigationController: navigationController, ssm: ssm)
        myQRCodeViewCoordinator.start()
    }
    
    public func sesameDeleted() {
        navigationController.popToRootViewController(animated: true)
    }
}
