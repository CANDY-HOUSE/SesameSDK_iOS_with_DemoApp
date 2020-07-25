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
    private var sesame2: CHSesame2
    
    init(navigationController: UINavigationController, sesame2: CHSesame2) {
        self.navigationController = navigationController
        self.sesame2 = sesame2
    }
    
    public func start() {
        guard let myQRCodeViewController = UIStoryboard.viewControllers.myQRCodeViewController else {
            return
        }
        let viewModel = MyQRViewModel(sesame2: sesame2, qrCodeType: .shareKey)
        myQRCodeViewController.viewModel = viewModel
        navigationController.pushViewController(myQRCodeViewController, animated: true)
    }
}
