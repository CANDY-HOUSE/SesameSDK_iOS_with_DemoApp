//
//  BluetoothDeviceListCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/18.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public final class BluetoothDevicesListCoordinator: Coordinator {
    public var childCoordinators: [String: Coordinator] = [:]
    public var parentCoordinator: Coordinator?
    public weak var presentedViewController: UIViewController?
    public let navigationController: UINavigationController
    
    public init(navigationViewController: UINavigationController) {
        self.navigationController = navigationViewController
    }
    
    public func start() {
        let bluetoothListViewController = UIStoryboard.viewControllers.bluetoothDevicesListViewController
        let deviceListViewModel = BluetoothDevicesListViewModel(coordinator: self)
        bluetoothListViewController?.viewModel = deviceListViewModel
        deviceListViewModel.delegate = self //  BluetoothDevicesListViewModelDelegate
        presentedViewController = bluetoothListViewController
        guard let presentingViewController = presentedViewController else {
            return
        }
        navigationController.pushViewController(presentingViewController, animated: false)
    }
    
    public func childCoordinatorDismissed(_ coordinator: Coordinator, userInfo: [String: Any]) {
        if let _ = coordinator as? RegisterDeviceListViewCoordinator,
            let dismissReason = userInfo[RegisterDeviceListViewCoordinator.DismissReason.key] as? RegisterDeviceListViewCoordinator.DismissReason,
            dismissReason == RegisterDeviceListViewCoordinator.DismissReason.registerSucceeded {
            presentedViewController?.viewWillAppear(true)
        } else if let _ = coordinator as? ScanViewCoordinator,
            let dismissReason = userInfo[ScanViewCoordinator.DismissReason.key] as? ScanViewCoordinator.DismissReason,
            dismissReason == ScanViewCoordinator.DismissReason.registerSucceeded {
            presentedViewController?.viewWillAppear(true)
        }
    }
}

extension BluetoothDevicesListCoordinator: BluetoothDevicesListViewModelDelegate {
    public func enterTestMode(sesame2: CHSesame2) {
        guard let bluetoothSesameControlViewController = UIStoryboard.viewControllers.bluetoothSesameControlViewController else {
            return
        }
        bluetoothSesameControlViewController.sesame = sesame2
        navigationController.pushViewController(bluetoothSesameControlViewController, animated: true)
    }
    
    public func scanViewTapped() {
        let scanViewCoordinator = ScanViewCoordinator(navigationController: navigationController)
        scanViewCoordinator.parentCoordinator = self
        scanViewCoordinator.start()
    }
    
    public func newSesameTapped() {
        let registerDeviceViewCoordinator = RegisterDeviceListViewCoordinator(navigationController: navigationController)
        registerDeviceViewCoordinator.parentCoordinator = self
        registerDeviceViewCoordinator.start()
    }
    
    public func registerWifiModule2Tapped() {
        let registerWifiModule2ViewCoordinator = RegisterWifiModule2ViewCoordinator(navigationController: navigationController)
        registerWifiModule2ViewCoordinator.parentCoordinator = self
        registerWifiModule2ViewCoordinator.start()
    }
    
    public func bluetootheDevicesListViewDidTappedSesame2(_ sesame2: CHSesame2) {
        let sesame2RoomMainCoordinator = Sesame2HistoryViewCoordinator(navigationController: navigationController,
                                                                       sesame2: sesame2)
        sesame2RoomMainCoordinator.start()
    }
}
