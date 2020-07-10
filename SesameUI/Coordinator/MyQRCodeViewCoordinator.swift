//
//  MyQRCodeViewCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/21.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public final class MyQRCodeViewCoordinator: Coordinator {
    public var childCoordinators: [String : Coordinator] = [:]
    public var parentCoordinator: Coordinator?
    public weak var presentedViewController: UIViewController?
    var navigationController: UINavigationController
    private var ssm: CHSesame2
    
    init(navigationController: UINavigationController, ssm: CHSesame2) {
        self.navigationController = navigationController
        self.ssm = ssm
    }
    
    public func start() {
        guard let myQRCodeViewController = UIStoryboard.viewControllers.myQRCodeViewController else {
            return
        }
        let viewModel = MyQRViewModel(ssm: ssm, qrCodeType: .shareKey)
        myQRCodeViewController.viewModel = viewModel
        navigationController.pushViewController(myQRCodeViewController, animated: true)
    }
    
    
}
