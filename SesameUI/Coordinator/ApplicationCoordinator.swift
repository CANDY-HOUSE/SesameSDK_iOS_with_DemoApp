//
//  ApplicationCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/18.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

public class ApplicationCoordinator: Coordinator {
    public var childCoordinators: [String: Coordinator] = [:]
    public var parentCoordinator: Coordinator?
    public weak var presentedViewController: UIViewController?
    
    let window: UIWindow
    let rootViewController = UINavigationController()
    
    init(window: UIWindow) {
        self.window = window
        let generalTabCoordinator = GeneralTabViewCoordinator(navigationController: rootViewController)
        generalTabCoordinator.start()
        rootViewController.setNavigationBarHidden(true, animated: false)
    }
    
    public func start() {
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        presentedViewController = rootViewController
    }
}
