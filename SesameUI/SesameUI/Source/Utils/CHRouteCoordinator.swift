//
//  CHRouteCoordinator.swift
//  SesameUI
//  路由協調器
//  Created by eddy on 2023/12/12.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

public protocol CHRouteCoordinator {
    
    /// 首頁彈出 QR Code Scan 控制器
    func presentScanViewController()
    
    /// 彈出註冊配對設備控制權
    func presentRegisterSesame2ViewController()
    
    /// 彈出添加朋友
    func presentFindFriendsViewController(callback: @escaping (_ newVal: String) -> Void)
    
    /// 進入 Sesame2 歷史紀錄
    /// - Parameter sesame2: sesame2對象
    func navigateToSesame2History(_ sesame2: CHSesame2)
    
    /// 進入 Sesame2 設置
    /// - Parameter sesame2: sesame2對象
    func navigateToSesame2Setting(_ sesame2: CHSesame2)
    
    /// 進入 Sesame2 角度設置
    /// - Parameter sesame2: sesame2 對象
    func navigateToSesame2LockAngleSetting(_ sesame2: CHSesame2)
    
    /// 進入 Sesame5 歷史紀錄
    /// - Parameter sesame5: sesame5對象
    func navigateToSesame5History(_ sesame5: CHSesame5)
    
    /// 進入 Sesame5 設置
    /// - Parameter sesame5: sesame5對象
    func navigateToSesame5Setting(_ sesame5: CHSesame5)
    
    /// 進入 Sesame5 角度設置
    /// - Parameter sesame5: sesame5對象
    func navigateToSesame5LockAngleSetting(_ sesame5: CHSesame5)
    
    /// 進入 SesameBot1 設置
    /// - Parameter sesameBot: seamebot對象
    func navigateToSesameBotSettingViewController(_ sesameBot: CHSesameBot)
    
    /// 進入 Bike1 設置
    /// - Parameter bikeLock: bike1 對象
    func navigateToBikeLockSettingViewController(_ bikeLock: CHSesameBike)
    
    /// 進入 Bike2 設置
    /// - Parameter bikeLock2: bike2對象
    func navigateToBike2SettingViewController(_ bikeLock2: CHSesameBike2)
    
    /// 進入 網關2設置頁
    /// - Parameters:
    ///   - wifiModule2: wifiModule2對象
    ///   - isFromRegister: 是否來自註冊
    func navigateToWifiModule2SettingViewController(_ wifiModule2: CHWifiModule2, isFromRegister: Bool)
    
    /// 進入 TouchPro 設置
    /// - Parameters:
    ///   - device: device對象
    ///   - isFromRegister: 是否來自註冊
    func navigateToCHSesameTouchProSettingVC(_ device: CHSesameTouchPro, isFromRegister: Bool)
    
    /// 進入 openSensor 設置
    /// - Parameters:
    ///   - device: device對象
    ///   - isFromRegister: 是否來自註冊
    func navigateToOpenSensorSettingVC(_ device: CHSesameTouchPro, isFromRegister: Bool)
    
    /// 進入 OpenSensor 重置頁
    /// - Parameters:
    ///   - device: device對象
    ///   - isFromRegister: 是否來自註冊
    func navigateToOpenSensorResetVC(_ device: CHSesameTouchPro, isFromRegister: Bool)
    
    /// 進入 BLE connector 設置
    /// - Parameters:
    ///   - device: device對象
    ///   - isFromRegister: 是否來來自註冊
    func navigateToBleConnectorVC(_ device: CHSesameTouchPro, isFromRegister: Bool)
    
    /// 進入 Bot2 設置
    /// - Parameter bot2: bot2對象
    func navigateToBot2SettingViewController(_ bot2: CHSesameBot2)
    
    /// 進入 Bot2 動作列表
    /// - Parameter device: device對象
    func navigateToSesameBot2VC(_ device: CHSesameBot2)
    
    /// 進入 Hub3 設置
    /// - Parameter hub3: hub3對象
    /// - Parameter isFromRegister: 是否來來自註冊
    func navigateToHub3SettingViewController(_ hub3: CHHub3, isFromRegister: Bool)
    
    /// 進入IR 設置
    /// - Parameter device: device 對象
//    func navigateToIRControlSettingVC(_ device: CHWifiModule2)

    /// 進入 Matter 类型设置
    /// - Parameter device: （ Hub3 對象，device 對象）
    func navigateToMatterTypeSettingVC(_ tuple: (CHHub3, CHDevice))
    
//    func navigateToRemoteCtlController(_ tuple: (CHHub3, ETDevice), _ homePage: Bool)
}

public extension CHRouteCoordinator where Self: UIViewController {
    func presentScanViewController() {
        let qrCodeScanViewController = QRCodeScanViewController.instance() { qrCodeType in
            if qrCodeType == .sesameKey {
                executeOnMainThread {
                    if let navController = GeneralTabViewController.switchTabByIndex(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
                        listViewController.getKeysFromCache()
                    }
                }
            } else if qrCodeType == .friend {
                if let nav = GeneralTabViewController.switchTabByIndex(1) as? UINavigationController,
                   let friendViewController = nav.viewControllers.first as? FriendListViewController {
                    friendViewController.reloadFriends()
                }
            }
        }
        present(qrCodeScanViewController, animated: true, completion: {})
    }

    func presentRegisterSesame2ViewController() {
        let registerSesame2ViewController = RegisterSesameDeviceViewController.instance { registeredDevice in
            executeOnMainThread {
                if let navController = GeneralTabViewController.switchTabByIndex(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
                    if let device = registeredDevice as? CHSesame2 {
                        listViewController.navigateToSesame2LockAngleSetting(device)
                    }
                    if let device = registeredDevice as? CHSesame5 {
                        listViewController.navigateToSesame5LockAngleSetting(device)
                    }
                    if let device = registeredDevice as? CHHub3 {
                        listViewController.navigateToHub3SettingViewController(device, isFromRegister: true)
                    }
                    else if let device = registeredDevice as? CHWifiModule2 {
                        listViewController.navigateToWifiModule2SettingViewController(device, isFromRegister: true)
                    }
                    if let device = registeredDevice as? CHSesameTouchPro {
                        if(device.productModel == .openSensor || device.productModel == .remoteNano){
                            listViewController.navigateToOpenSensorSettingVC(device, isFromRegister: true)
                        }else if(device.productModel == .bleConnector || device.productModel == .remote){
                            listViewController.navigateToBleConnectorVC(device, isFromRegister: true)
                        }else{
                            listViewController.navigateToCHSesameTouchProSettingVC(device, isFromRegister: true)
                        }
                    } else if let device = registeredDevice as? CHSesameTouch {
                        listViewController.navigateToCHSesameBiometricSettingVC(device, isFromRegister: true)
                    } else if let device = registeredDevice as? CHSesameFace {
                        listViewController.navigateToCHSesameBiometricSettingVC(device, isFromRegister: true)
                    } else if let device = registeredDevice as? CHSesameFacePro {
                        listViewController.navigateToCHSesameBiometricSettingVC(device, isFromRegister: true)
                    }
                    listViewController.getKeysFromCache()
                }
            }
        }
        present(registerSesame2ViewController.navigationController!, animated: true, completion: nil)
    }
    
    func presentFindFriendsViewController(callback: @escaping (_ newVal: String) -> Void) {
        let dialog = ChangeValueDialog.show("", title: "co.candyhouse.sesame2.AddContacts".localized, placeHolder: " friend@email.com", hint: "co.candyhouse.sesame2.findFriendHint".localized, callBack: callback)
        dialog.valueTextField.keyboardType = .emailAddress
    }
    
    func navigateToSesame2History(_ sesame2: CHSesame2) {
        navigationController?.pushViewController(SesameHistoryViewController.instance(sesame2, dismissHandler: nil, settingClickHandler: { [weak self] in
            self?.navigationController?.pushViewController(Sesame2SettingViewController.instanceWithSesame2(sesame2) { _ in }, animated: true)
        }), animated: true)
    }
    
    func navigateToSesame5History(_ sesame5: CHSesame5) {
        navigationController?.pushViewController(SesameHistoryViewController.instance(sesame5, dismissHandler: nil, settingClickHandler: { [weak self] in
            self?.navigationController?.pushViewController(Sesame5SettingViewController.instance(sesame5) { _ in }, animated: true)
        }), animated: true)
    }
    
    func navigateToSesame5Setting(_ sesame5: CHSesame5) {
        navigationController?.pushViewController(Sesame5SettingViewController.instance(sesame5) { _ in /** self.getKeysFromCache()*/}, animated: true)
    }
    
    func navigateToSesame2Setting(_ sesame2: CHSesame2) {
        navigationController?.pushViewController(Sesame2SettingViewController.instanceWithSesame2(sesame2) { _ in /** self.getKeysFromCache()*/}, animated: true)
    }
    
    func navigateToSesame2LockAngleSetting(_ sesame2: CHSesame2) {
        navigationController?.pushViewController(LockAngleSettingViewController.instanceWithSesame2(sesame2) {/** self.getKeysFromCache()*/ }, animated: true)
    }
    
    func navigateToSesame5LockAngleSetting(_ sesame5: CHSesame5) {
        navigationController?.pushViewController(Sesame5LockAngleViewController.instance(sesame5) { /** self.getKeysFromCache()*/ }, animated: true)
    }

    func navigateToSesameBotSettingViewController(_ sesameBot: CHSesameBot) {
        navigationController?.pushViewController(SesameBotSettingViewController.instanceWithSwitch(sesameBot) {/** self.getKeysFromCache()*/ },animated: true)
    }

    func navigateToBikeLockSettingViewController(_ bikeLock: CHSesameBike) {
        navigationController?.pushViewController(BikeLockSettingViewController.instanceWithBikeLock(bikeLock) {},animated: true)
    }
    
    func navigateToBike2SettingViewController(_ bikeLock2: CHSesameBike2) {
        navigationController?.pushViewController(BikeLock2SettingViewController.instanceWithBikeLock2(bikeLock2) {_ in },animated: true)
    }
    
    func navigateToBot2SettingViewController(_ bot2: CHSesameBot2) {
        navigationController?.pushViewController(Bot2SettingViewController.instanceWithBikeBot2(bot2), animated: true)
    }

    func navigateToWifiModule2SettingViewController(_ wifiModule2: CHWifiModule2, isFromRegister: Bool = false) {
        navigationController?.pushViewController(WifiModule2SettingViewController.instanceWithWifiModule2(wifiModule2, isFromRegister: isFromRegister) {/** self.getKeysFromCache()*/  },animated: true)
    }

    func navigateToCHSesameTouchProSettingVC(_ device: CHSesameTouchPro, isFromRegister: Bool = false) {
        navigationController?.pushViewController(SesameBiometricDeviceSettingVC.instance(device) {},animated: true)
    }
    
    func navigateToOpenSensorSettingVC(_ device: CHSesameTouchPro, isFromRegister: Bool = false) {
        navigationController?.pushViewController(OpenSensorSettingVC.instance(device) {},animated: true)
    }
    
    func navigateToOpenSensorResetVC(_ device: CHSesameTouchPro, isFromRegister: Bool = false) {
        navigationController?.pushViewController(OpenSensorResetHintVC.instance(device) {},animated: true)
    }
    
    func navigateToBleConnectorVC(_ device: CHSesameTouchPro, isFromRegister: Bool = false) {
        navigationController?.pushViewController(BleConnectorSettingVC.instance(device) {},animated: true)
    }
    
    func navigateToSesameBot2VC(_ device: CHSesameBot2){
        present(Bot2ScriptActionVC.instance(device).navigationController!, animated: true, completion: {  })
    }
    
    func navigateToHub3SettingViewController(_ hub3: CHHub3, isFromRegister: Bool = false) {
        navigationController?.pushViewController(Hub3SettingViewController.instanceWithHub3(hub3, isFromRegister: isFromRegister) {},animated: true)
    }
    
//    func navigateToIRControlSettingVC(_ device: CHWifiModule2) {
//        navigationController?.pushViewController(Hub3IRCustomizeControlVC.instance(),animated: true)
//    }
    
    func navigateToMatterTypeSettingVC(_ tuple: (CHHub3, CHDevice)) {
        navigationController?.pushViewController(Hub3MatterTypeSelectVC.instance(tuple),animated: true)
    }
    
    func navigateToCHSesameFaceProSettingVC(_ device: CHSesameFacePro, isFromRegister: Bool = false) {
        navigationController?.pushViewController(SesameBiometricDeviceSettingVC.instance(device) {},animated: true)
    }
    
    func navigateToCHSesameBiometricSettingVC(_ device: CHSesameBasePro, isFromRegister: Bool = false) {
        navigationController?.pushViewController(SesameBiometricDeviceSettingVC.instance(device) {},animated: true)
    }
}

class CustomPresentationController: UIPresentationController {
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {
            return .zero
        }
        let containerBounds = containerView.bounds
        let contentHeight = containerBounds.height * 0.65
        return CGRect(x: 0, y: containerBounds.height - contentHeight, width: containerBounds.width, height: contentHeight)
    }
}

class MyTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    static let shared = MyTransitioningDelegate()
    private override init() {}

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CustomPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
