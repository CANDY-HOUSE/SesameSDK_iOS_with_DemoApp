//
//  OpenSensorResetHintView.swift
//  SesameUI
//
//  Created by JOi Chao on 2023/7/14.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import AWSMobileClientXCF
import SesameSDK
import NordicDFU
import CoreBluetooth
import IntentsUI

let kTagModelView = 101
class OpenSensorResetHintVC: CHBaseViewController, CHDeviceStatusDelegate,CHSesameConnectorDelegate, DeviceControllerHolder {
    // MARK: DeviceControllerHolder impl
    var device: SesameSDK.CHDevice!
    
    var mDevice: CHSesameTouchPro! {
        didSet {
            device = mDevice
        }
    }
    
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
    var dismissHandler: (()->Void)?

    deinit {
        mDevice.disconnect(){ _ in}
        self.deviceMemberWebView?.cleanup()
    }
    
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc func reloadFriends() {
        reloadMembers()
        refreshControl.endRefreshing()
    }
    
    // MARK: ArrangeSubviews
    func arrangeSubviews() {
        // MARK: Group
        contentStackView.addArrangedSubview(deviceMemberWebView(device))
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        refreshControl.attributedTitle = NSAttributedString(string: "co.candyhouse.sesame2.PullToRefresh".localized)
        refreshControl.addTarget(self, action: #selector(reloadFriends), for: .valueChanged)
        scrollView.refreshControl = refreshControl

        // MARK: 機種
        let modelView = CHUIViewGenerator.plain()
        modelView.title = "co.candyhouse.sesame2.model".localized
        modelView.value = mDevice.productModel.deviceModelName()
        modelView.tag = kTagModelView
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
        hintLabel.text =  String(format: "co.candyhouse.sesame2.pleaseResetOpenSensor".localized, arguments: [modelView.value, modelView.value])
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
            self.prepareConfirmDropKey(sender as! UIView) {
                self.navigationController?.popToRootViewController(animated: false)
            }
        }
        dropKeyView.title = String(format: "co.candyhouse.sesame2.TrashTouch".localized, arguments: [modelView.value])
        contentStackView.addArrangedSubview(dropKeyView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Drop key hint
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = String(format: "co.candyhouse.sesame2.dropKeyDesc".localized, arguments: [modelView.value, modelView.value, modelView.value])
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
            self.prepareConfirmResetKey(sender as! UIView) {}
        }
        resetKeyView.title = "co.candyhouse.sesame2.ResetSesame".localized
        contentStackView.addArrangedSubview(resetKeyView)
#endif
        let spacerView = UIView()
        contentStackView.addArrangedSubview(spacerView)
        NSLayoutConstraint.activate([
            spacerView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
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

