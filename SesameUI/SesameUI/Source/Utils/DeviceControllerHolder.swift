//
//  DeviceHolder.swift
//  SesameUI
//
//  Created by eddy on 2024/1/25.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
import AWSMobileClientXCF

protocol DeviceControllerHolder: AnyObject, ShareAlertConfigurator {
    
    var device: CHDevice! { get set }
    /// 刪除芝麻🔑
    /// - Parameter device: 設備
    func prepareConfirmDropKey(_ sender: UIView, completion: @escaping () -> Void)

    /// 重置芝麻🔑  [Debug only]
    /// - Parameter device: 設備
    func prepareConfirmResetKey(_ sender: UIView, completion: @escaping () -> Void)
}

extension DeviceControllerHolder where Self: CHBaseViewController {
    
    func prepareConfirmDropKey(_ sender: UIView, completion: @escaping () -> Void) {
        modalSheet(AlertModel(title: nil, message: nil, sourceView: sender, items: [
            AlertItem(title: String(format: "co.candyhouse.sesame2.TrashTouch".localized, arguments: [self.device.deviceName]), style: .destructive, handler: { [unowned self] _ in
                dropKey { [weak self] in
                    guard let self = self else { return }
                    self.refreshDeviceFromCache()
                    completion()
                }
            }),
            AlertItem.cancelItem()
        ]))
    }
    
    func prepareConfirmResetKey(_ sender: UIView, completion: @escaping () -> Void) {
        modalSheet(AlertModel(title: nil, message: nil, sourceView: sender, items: [
            AlertItem(title: "co.candyhouse.sesame2.ResetSesame".localized, style: .destructive, handler: { [unowned self] _ in
                resetKey { [weak self] in
                    guard let self = self else { return }
                    self.refreshDeviceFromCache()
                    completion()
                }
            }),
            AlertItem.cancelItem()
        ]))
    }
    
    fileprivate func refreshDeviceFromCache() {
        if let navController = GeneralTabViewController.getTabViewControllersBy(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
            listViewController.refreshData()
        }
    }
        
    fileprivate func dropKey(completion: @escaping () -> Void?) {
        let device = self.device!
        let resetHandler: () -> Void = {
            ViewHelper.hideLoadingView(view: self.view)
            Sesame2Store.shared.deletePropertyFor(device)
            self.device.unregisterNotification()
            if let bot2 = device as? CHSesameBot2 {
                Bot2InitHelper.clearBotScript(device: bot2) { _ in}
            }
            device.dropKey() { resetResult in
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
                    completion()
                }
            }
        }
        ViewHelper.showLoadingInView(view: self.view)
        CHAPIClient.shared.deleteCHUserKey(CHUserKey.fromCHDevice(device).deviceUUIDData()) { deleteResult in
            if case .failure(let err) = deleteResult {
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
                    self.view.makeToast(err.errorDescription())
                }
            } else {
                executeOnMainThread {
                    resetHandler()
                }
            }
        }
    }
    
    fileprivate func resetKey(completion: @escaping () -> Void?) {
        let device = self.device!
        let resetHandler: () -> Void = {
            ViewHelper.hideLoadingView(view: self.view)
            Sesame2Store.shared.deletePropertyFor(device)
            self.device.unregisterNotification()
            if let bot2 = device as? CHSesameBot2 {
                Bot2InitHelper.clearBotScript(device: bot2) { _ in}
            }
            device.reset { resetResult in
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
                    completion()
                }
            }
        }
        ViewHelper.showLoadingInView(view: self.view)
        CHAPIClient.shared.deleteCHUserKey(CHUserKey.fromCHDevice(device).deviceUUIDData()) { deleteResult in
            if case let .failure(err) = deleteResult {
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
                    self.view.makeToast(err.errorDescription())
                }
            } else {
                executeOnMainThread {
                    resetHandler()
                }
            }
        }
    }
}
