//
//  Sesame2SettingViewControllerCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public final class Sesame2SettingViewControllerCoordinator: Coordinator {
    public var childCoordinators: [String : Coordinator] = [:]
    public var parentCoordinator: Coordinator?
    public weak var presentedViewController: UIViewController?
    var navigationController: UINavigationController
    private var sesame2: CHSesame2
    
    public init(navigationController: UINavigationController, sesame2: CHSesame2) {
        self.navigationController = navigationController
        self.sesame2 = sesame2
    }
    
    public func start() {
        guard let sesame2SettingViewController = UIStoryboard.viewControllers.sesame2SettingVC else {
            return
        }
        
        let viewModel = Sesame2SettingViewModel(sesame2: sesame2)
        viewModel.delegate = self
        sesame2SettingViewController.viewModel = viewModel
        presentedViewController = sesame2SettingViewController
        navigationController.pushViewController(sesame2SettingViewController, animated: true)
    }
    
    deinit {
        L.d("Sesame2SettingViewControllerCoordinator deinit")
    }
}

extension Sesame2SettingViewControllerCoordinator: Sesame2SettingViewModelDelegate {
    public func setAngleForSesame2(_ sesame2: CHSesame2) {
        let lockAngleSettingViewCoordinator = LockAngleSettingViewCoordinator(navigationController: navigationController, sesame2: sesame2)
        lockAngleSettingViewCoordinator.start()
    }
    
    public func shareSesame2Tapped(_ sesame2: CHSesame2) {
        let myQRCodeViewCoordinator = MyQRCodeViewCoordinator(navigationController: navigationController, sesame2: sesame2)
        myQRCodeViewCoordinator.start()
    }
    
    public func sesame2Deleted() {
        navigationController.popToRootViewController(animated: true)
    }
}
