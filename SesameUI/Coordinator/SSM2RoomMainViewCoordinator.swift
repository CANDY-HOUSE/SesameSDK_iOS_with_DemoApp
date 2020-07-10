//
//  SSM2RoomMainVCCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public final class SSM2RoomMainViewCoordinator: Coordinator {
    public var childCoordinators: [String : Coordinator] = [:]
    public var parentCoordinator: Coordinator?
    public weak var presentedViewController: UIViewController?
    private let ssm: CHSesame2
    
    let navigationController: UINavigationController
    
    public init(navigationController: UINavigationController, ssm: CHSesame2) {
        self.navigationController = navigationController
        self.ssm = ssm
    }
    
    public func start() {
        guard let ssm2RoomMainViewController = UIStoryboard.viewControllers.ssm2RoomMainVC else {
            return
        }
        navigationController.navigationItem.backBarButtonItem?.setBackgroundImage(
            UIImage.SVGImage(named: "icons_outlined_addoutline")
            , for: .normal, barMetrics: .default)
        let viewModel = SSM2RoomMainViewModel(ssm: ssm)
        viewModel.delegate = self
        ssm2RoomMainViewController.viewModel = viewModel
        navigationController.pushViewController(ssm2RoomMainViewController, animated: true)
        presentedViewController = ssm2RoomMainViewController
    }
    
    deinit {
        L.d("SSM2RoomMainVCCoordinator deinit")
    }
}

extension SSM2RoomMainViewCoordinator: SSM2RoomMainViewModelDelegate {
    public func rightButtonTappedWithSSM(_ ssm: CHSesame2) {
        let ssm2SettingViewCoordinator = SSM2SettingViewControllerCoordinator(navigationController: navigationController,
                                                                              ssm: ssm)
        ssm2SettingViewCoordinator.start()
    }
}
