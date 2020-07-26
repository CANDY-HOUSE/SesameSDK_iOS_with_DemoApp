//
//  Sesame2RoomMainVCCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public final class Sesame2RoomMainViewCoordinator: Coordinator {
    public var childCoordinators: [String : Coordinator] = [:]
    public var parentCoordinator: Coordinator?
    public weak var presentedViewController: UIViewController?
    private let sesame2: CHSesame2
    
    let navigationController: UINavigationController
    
    public init(navigationController: UINavigationController, sesame2: CHSesame2) {
        self.navigationController = navigationController
        self.sesame2 = sesame2
    }
    
    public func start() {
        guard let sesame2RoomMainViewController = UIStoryboard.viewControllers.sesame2RoomMainVC else {
            return
        }
        navigationController.navigationItem.backBarButtonItem?.setBackgroundImage(
            UIImage.SVGImage(named: "icons_outlined_addoutline")
            , for: .normal, barMetrics: .default)
        let viewModel = Sesame2HistoryViewModel(sesame2: sesame2)
        viewModel.delegate = self
        sesame2RoomMainViewController.viewModel = viewModel
        navigationController.pushViewController(sesame2RoomMainViewController, animated: true)
        presentedViewController = sesame2RoomMainViewController
    }
    
    deinit {
        L.d("Sesame2RoomMainVCCoordinator deinit")
    }
}

extension Sesame2RoomMainViewCoordinator: Sesame2HistoryViewModelDelegate {
    public func rightButtonTappedWithSesame2(_ sesame2: CHSesame2) {
        let sesame2SettingViewCoordinator = Sesame2SettingViewControllerCoordinator(navigationController: navigationController,
                                                                              sesame2: sesame2)
        sesame2SettingViewCoordinator.start()
    }
}
