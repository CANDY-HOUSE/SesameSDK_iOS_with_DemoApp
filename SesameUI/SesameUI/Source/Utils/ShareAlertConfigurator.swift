//
//  ShareAlertConfigurator.swift
//  SesameUI
//  鑰匙🔑分享配置
//  Created by eddy on 2023/12/12.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

public struct AlertItem {
    var title: String!
    var style: UIAlertAction.Style = .default
    var handler:  ((UIAlertAction) -> Void)?
    
    static func cancelItem() -> AlertItem {
        return AlertItem(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel) { _ in }
    }
}

public struct AlertModel {
    var title: String?
    var message: String?
    var style: UIAlertController.Style = .actionSheet
    var sourceView: UIView?
    var items: [AlertItem] = [AlertItem]()
}

public protocol ShareAlertConfigurator {
    func modalSheet(_ model: AlertModel)
}

public extension ShareAlertConfigurator where Self: UIViewController {
    
    /// 彈出 sheet
    /// - Parameter model: 數據模型，model 中sourceView的参数必须使用具体的控件的cell。否则在ipad或者某些特定场景将无法弹出。
   
    func modalSheet(_ model: AlertModel) {
        let alertController = UIAlertController(title: model.title, message: model.message, preferredStyle: model.style)
        for item in model.items {
            let action = UIAlertAction(title: item.title, style: item.style, handler: item.handler)
            alertController.addAction(action)
        }
        alertController.popoverPresentationController?.sourceView = model.sourceView ?? view
        present(alertController, animated: true, completion: {})
    }
}

extension ShareAlertConfigurator where Self: UIViewController {
    /// 根據角色等級彈出彈出 sheet
    /// - Parameters:
    ///   - device: 要分享鑰匙的設備
    ///   - sender: 被操作的视图
    ///   - completionHandler: 完成回調
    internal func modalSheetToQRControlByRoleLevel(device: CHDevice, sender: UIView?, completionHandler: @escaping ((Bool) -> Void?)) {
        var alertItems = [AlertItem]()
        switch device.keyLevel {
        case KeyLevel.owner.rawValue:
            alertItems.append(AlertItem(title: "co.candyhouse.sesame2.ownerKey".localized, handler: { _ in
                let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(device, keyLevel: KeyLevel.owner.rawValue) {
                    completionHandler(true)
                }
                self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
            }))
            fallthrough
        case KeyLevel.manager.rawValue:
            alertItems.append(AlertItem(title: "co.candyhouse.sesame2.managerKey".localized, handler: { _ in
                let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(device, keyLevel: KeyLevel.manager.rawValue)  {
                    completionHandler(true)
                }
                self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
            }))
            fallthrough
        case KeyLevel.guest.rawValue:
            alertItems.append(AlertItem(title: "co.candyhouse.sesame2.memberKey".localized, handler: { _ in
                if device.keyLevel == KeyLevel.guest.rawValue {
                    let qrCode = URL.qrCodeURLFromDevice(device, deviceName: device.deviceName, keyLevel: KeyLevel.guest.rawValue)
                    let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(device,qrCode: qrCode!)
                    self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
                } else {
                    let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(device, keyLevel: KeyLevel.guest.rawValue) {
                        completionHandler(true)
                    }
                    self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
                }
            }))
            fallthrough
        default:
            alertItems.append(AlertItem(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: { _ in } ))
        }
        modalSheet(AlertModel(message: "co.candyhouse.sesame2.ShareFriend".localized, sourceView: sender, items: alertItems))
    }
}

