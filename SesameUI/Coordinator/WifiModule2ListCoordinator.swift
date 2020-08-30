//
//  WifiModule2ListCoordinator.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public final class WifiModule2ListCoordinator: Coordinator {
    public var childCoordinators: [String : Coordinator] = [:]
    public var parentCoordinator: Coordinator?
    public weak var presentedViewController: UIViewController?
    public var presentingViewController: UIViewController
    
    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }
    
    public func start() {
        let viewModel = WifiModule2ListViewModel()
        let viewController = UIStoryboard.viewControllers.wifiModule2ListViewController!
        viewController.viewModel = viewModel
        presentedViewController = viewController
        presentingViewController.present(presentedViewController!,
                                         animated: true, completion: nil)
    }
    
//    deinit {
//        L.d("WifiSelectionViewCoordinator deinit")
//    }
}
