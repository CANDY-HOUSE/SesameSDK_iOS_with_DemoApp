//
//  RegisterWifiModule2ViewCoordinator.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public final class RegisterWifiModule2ViewCoordinator: Coordinator {
    private var wifiNotify: ((Wifi)->Void)?
    
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
        guard let registerWifiModule2ViewController = UIStoryboard.viewControllers.registerWifiModule2TableViewController else {
            return
        }
        let viewModel = RegisterWifiModule2ViewModel()
        viewModel.delegate = self
        registerWifiModule2ViewController.viewModel = viewModel
        presentedViewController = registerWifiModule2ViewController
        navigationController.present(registerWifiModule2ViewController, animated: true, completion: nil)
    }
    
    public func childCoordinatorDismissed(_ coordinator: Coordinator, userInfo: [String: Any]) {
        if let wifi = userInfo["wifi"] as? Wifi {
            self.wifiNotify?(wifi)
        }
    }
    
//    deinit {
//        L.d("RegisterWifiModule2ViewCoordinator")
//    }
}

extension RegisterWifiModule2ViewCoordinator: RegisterWifiModule2ViewModelDelegate {
    func didSelectedWifi(_ wifiNotify: @escaping (Wifi)->Void) {
        self.wifiNotify = wifiNotify
    }
    
    public func didSelectedWifiModule2(_ wifiModule2: CHWifiModule2) {
        let wifiSelectionCoordinator = WifiSelectionViewCoordinator(presentingViewController: presentedViewController!, wifiModule2: wifiModule2)
        wifiSelectionCoordinator.parentCoordinator = self
        wifiSelectionCoordinator.start()
    }
    
    public func registerWifiModule2Succeed() {
        presentedViewController?.dismiss(animated: true, completion: nil)
    }
}
