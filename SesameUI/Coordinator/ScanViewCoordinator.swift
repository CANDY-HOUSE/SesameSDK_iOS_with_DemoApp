//
//  ScanViewCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

public final class ScanViewCoordinator: Coordinator {
    public enum DismissReason: String {
        static let key = "DismissReason"
        case cancel, registerSucceeded
    }
    
    public var childCoordinators: [String : Coordinator] = [:]
    public var parentCoordinator: Coordinator?
    public weak var presentedViewController: UIViewController?
    private var navigationController: UINavigationController
    
    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    public func start() {
        guard let scanViewController = UIStoryboard.viewControllers.scanViewController else {
            return
        }
        let viewModel = ScanViewModel()
        viewModel.delegate = self
        scanViewController.viewModel = viewModel
        presentedViewController = scanViewController
        navigationController.present(scanViewController, animated: true, completion: nil)
    }
}

extension ScanViewCoordinator: ScanViewModelDelegate {
    func receivedSesame2() {
        presentedViewController?.dismiss(animated: true, completion: nil)
        parentCoordinator?.childCoordinatorDismissed(self, userInfo: [DismissReason.key: DismissReason.registerSucceeded])
    }
}
