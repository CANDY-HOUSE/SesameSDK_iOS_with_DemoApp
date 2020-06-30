//
//  ScanViewCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

public final class ScanViewCoordinator: Coordinator {
    public var childCoordinators: [String : Coordinator] = [:]
    
    public weak var presentedViewController: UIViewController?
    private var navigationController: UINavigationController
    
    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    public func start() {
        guard let scanViewController = UIStoryboard.viewControllers.scanViewController else {
            return
        }
        navigationController.present(scanViewController, animated: true, completion: nil)
    }
}
