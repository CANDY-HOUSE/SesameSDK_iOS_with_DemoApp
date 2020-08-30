//
//  WifiSelectionViewCoordinator.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public final class WifiSelectionViewCoordinator: Coordinator {
    public var childCoordinators: [String : Coordinator] = [:]
    public var parentCoordinator: Coordinator?
    public weak var presentedViewController: UIViewController?
    public var presentingViewController: UIViewController
    
    private var wifiModule2: CHWifiModule2
    
    init(presentingViewController: UIViewController, wifiModule2: CHWifiModule2) {
        self.presentingViewController = presentingViewController
        self.wifiModule2 = wifiModule2
    }
    
    public func start() {
        let viewModel = WifiSelectionTableViewModel(wifiModule2: wifiModule2)
        viewModel.delegate = self
        let viewController = UIStoryboard.viewControllers.wifiSelectionTableViewController!
        viewController.viewModel = viewModel
        presentedViewController = viewController
        presentingViewController.present(presentedViewController!,
                                         animated: true, completion: nil)
    }
    
//    deinit {
//        L.d("WifiSelectionViewCoordinator deinit")
//    }
}

extension WifiSelectionViewCoordinator: WifiSelectionTableViewModelDelegate {
    func didSelectedWifi(_ wifi: Wifi) {
        presentedViewController?.dismiss(animated: true, completion: nil)
        parentCoordinator?.childCoordinatorDismissed(self, userInfo: ["wifi": wifi])
    }
}
