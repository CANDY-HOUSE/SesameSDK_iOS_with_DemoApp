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
}

extension BluetoothDevicesListCoordinator: BluetoothDevicesListViewModelDelegate {
    public func enterTestMode(ssm: CHSesameBleInterface) {
        guard let bluetoothSesameControlViewController = UIStoryboard.viewControllers.bluetoothSesameControlViewController else {
            return
        }
        bluetoothSesameControlViewController.sesame = ssm
        navigationController.pushViewController(bluetoothSesameControlViewController, animated: true)
    }
    
    public func scanViewTapped() {
        let scanViewCoordinator = ScanViewCoordinator(navigationController: navigationController)
        scanViewCoordinator.start()
    }
    
    public func newSesameTapped() {
        let registerDeviceViewCoordinator = RegisterDeviceListViewCoordinator(navigationController: navigationController)
        registerDeviceViewCoordinator.start()
    }
    
    public func bluetootheDevicesListViewDidTappedSSM(_ ssm: CHSesameBleInterface) {
        let ssm2RoomMainCoordinator = SSM2RoomMainViewCoordinator(navigationController: navigationController,
                                                                ssm: ssm)
        ssm2RoomMainCoordinator.start()
    }
}
