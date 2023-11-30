//
//  OpenSensorResetHintView.swift
//  SesameUI
//
//  Created by JOi Chao on 2023/7/14.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK
import NordicDFU
import CoreBluetooth
import IntentsUI

class OpenSensorResetHintVC: CHBaseViewController, CHDeviceStatusDelegate,CHSesameConnectorDelegate {
    var mDevice: CHSesameTouchPro!
    
    // MARK: - Data model
    lazy var localDevices: [CHDevice] = {
        var chDevices = [CHDevice]()
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                chDevices = devices.data
            }
        }
        return chDevices
    }()

    // MARK: - UI Componets
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var changeNameView: CHUIPlainSettingView!
    var dismissHandler: (()->Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .sesame2Gray
        scrollView.addSubview(contentStackView)
        view.addSubview(scrollView)
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 0
        contentStackView.distribution = .fill
        UIView.autoLayoutStackView(contentStackView, inScrollView: scrollView)
        
        self.arrangeSubviews()
    }

    deinit{ mDevice.disconnect(){ _ in} }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: ArrangeSubviews
    func arrangeSubviews() {
        // MARK: Change name
        changeNameView = CHUIViewGenerator.plain { [unowned self] _,_ in
            ChangeValueDialog.show(mDevice.deviceName, title: "co.candyhouse.sesame2.EditName".localized) { name in
                self.mDevice.setDeviceName(name)
                self.changeNameView.value = name
                if let navController = GeneralTabViewController.getTabViewControllersBy(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
                    listViewController.reloadTableView()
                }
            }
        }
        changeNameView.title = "co.candyhouse.sesame2.EditName".localized
        changeNameView.value = mDevice.deviceName
        contentStackView.addArrangedSubview(changeNameView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: 機種
        let modelView = CHUIViewGenerator.plain()
        modelView.title = "co.candyhouse.sesame2.model".localized
        modelView.value = mDevice.productModel.deviceModelName()
        contentStackView.addArrangedSubview(modelView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        // MARK: UUID
        let uuidView = CHUIViewGenerator.plain ()
        uuidView.title = "UUID".localized
        uuidView.value = mDevice.deviceId.uuidString
        contentStackView.addArrangedSubview(uuidView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))

        // MARK: Open Sensor reset hint
        let hintLabelContainer = UIView(frame: .zero)
        let hintLabel = UILabel(frame: .zero)
        hintLabel.text =  "co.candyhouse.sesame2.pleaseResetOpenSensor".localized
        hintLabel.textColor = UIColor.darkText
        hintLabel.numberOfLines = 0 // 設置為0時，允許無限換行
        hintLabel.lineBreakMode = .byWordWrapping // 按單詞換行
        hintLabelContainer.addSubview(hintLabel)
        hintLabel.autoPinLeading(constant: 30)
        hintLabel.autoPinTrailing(constant: -30)
        hintLabel.autoPinTop(constant: 30)
        hintLabel.autoPinBottom(constant: -30)
        contentStackView.addArrangedSubview(hintLabelContainer)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Drop key
        let dropKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.dropKey(sender: sender as! UIButton)
        }
        dropKeyView.title = String(format: "co.candyhouse.sesame2.TrashTouch".localized, arguments: ["co.candyhouse.sesame2.OpenSensor".localized])
        contentStackView.addArrangedSubview(dropKeyView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Drop key hint
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = String(format: "co.candyhouse.sesame2.dropKeyDesc".localized, arguments: ["co.candyhouse.sesame2.OpenSensor".localized, "co.candyhouse.sesame2.OpenSensor".localized, "co.candyhouse.sesame2.OpenSensor".localized])
        titleLabel.textColor = UIColor.placeHolderColor
        titleLabel.numberOfLines = 0 // 設置為0時，允許無限換行
        titleLabel.lineBreakMode = .byWordWrapping // 按單詞換行
        titleLabelContainer.addSubview(titleLabel)
        titleLabel.autoPinLeading(constant: 10)
        titleLabel.autoPinTrailing(constant: -10)
        titleLabel.autoPinTop()
        titleLabel.autoPinBottom()
        contentStackView.addArrangedSubview(titleLabelContainer)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))

#if DEBUG
        // MARK: Reset Sesame
        let resetKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.confirmReset(sender as! UIButton)
        }
        resetKeyView.title = "co.candyhouse.sesame2.ResetSesame".localized
        contentStackView.addArrangedSubview(resetKeyView)
#endif

    }
    func confirmReset(_ sender: UIButton) {
        let unregister = UIAlertAction(title: "co.candyhouse.sesame2.ResetSesame".localized,
                                       style: .destructive) { _ in
            self.resetSesame5()
        }
        let close = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized,
                                  style: .cancel) { (action) in }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(unregister)
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = sender
        present(alertController, animated: true, completion: nil)
    }
    func resetSesame5() {
        ViewHelper.showLoadingInView(view: view)
        Sesame2Store.shared.deletePropertyFor(self.mDevice)
        self.mDevice.unregisterNotification()
        self.mDevice.reset { resetResult in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.view)
            }
        }
    }
    
    // MARK: Trash Key
    func dropKey(sender: UIButton) {
        var title: String
            title = String(format: "co.candyhouse.sesame2.TrashTouch".localized, arguments: ["co.candyhouse.sesame2.OpenSensor".localized])
        
        let trashKey = UIAlertAction(title: title,style: .destructive) { (action) in
            ViewHelper.showLoadingInView(view: self.view)
            Sesame2Store.shared.deletePropertyFor(self.mDevice)
            self.mDevice.unregisterNotification()
            self.mDevice.dropKey() { _ in
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
                    self.navigationController?.popToRootViewController(animated: false)
                }
            }
        }
        
        let close = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil)
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(trashKey)
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = sender
        present(alertController, animated: true, completion: nil)
    }
}

extension OpenSensorResetHintVC{
    static func instance(_ device: CHSesameTouchPro, dismissHandler: (()->Void)? = nil) -> OpenSensorResetHintVC {
        let vc = OpenSensorResetHintVC(nibName: nil, bundle: nil)
        vc.hidesBottomBarWhenPushed = true
        vc.mDevice = device
        vc.dismissHandler = dismissHandler
        return vc
    }
}

