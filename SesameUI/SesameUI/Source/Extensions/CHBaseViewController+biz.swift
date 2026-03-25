//
//  CHBaseViewController+DeviceMember.swift
//  SesameUI
//
//  Created by eddy on 2025/9/18.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
import UIKit
import SesameSDK

// Device Owner Manage
extension CHBaseViewController {
    private struct WebAssociatedKeys {
        static var deviceWebViewKey: UInt8 = 0
    }
    var deviceMemberWebView: CHWebView? {
        get {
            return objc_getAssociatedObject(self, &WebAssociatedKeys.deviceWebViewKey) as? CHWebView
        }
        set {
            objc_setAssociatedObject(self, &WebAssociatedKeys.deviceWebViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func deviceMemberWebView(_ device: CHDevice) -> UIView {
        let collectionViewContainer = UIView(frame: .zero)
        let heightConstraint = collectionViewContainer.heightAnchor.constraint(equalToConstant: 80)
        heightConstraint.isActive = true
        let web = CHWebView.instanceWithScene("device-setting", extInfo: ["deviceUUID": device.deviceId.uuidString, "keyLevel": "\(device.keyLevel)"])
        self.deviceMemberWebView = web
        web.registerSchemeHandler("ssm://UI/webview/open") { [weak self] view, url, param in
            guard let self = self else {
                return
            }
            guard let urlStr = param["url"] else {
                return
            }
            if let notifyName = param["notifyName"] {
                NotificationCenter.default.addObserver(self, selector: #selector(onReceiveNotification(notify:)), name: Notification.Name(notifyName), object: nil)
            }
            self.navigationController?.pushViewController(CHWebViewController.instanceWithURL(urlStr), animated:true)
        }
        web.registerMessageHandler(WebViewMessageType.requestAutoLayoutHeight.rawValue) { webView, data in
            if let requestData = data as? [String: Any],
               let height = requestData["height"] as? CGFloat {
                heightConstraint.constant = height
                UIView.performWithoutAnimation {
                    if let parentView = collectionViewContainer.superview {
                        parentView.layoutIfNeeded()
                    }
                }
            }
        }
        collectionViewContainer.addSubview(web)
        web.autoPinEdgesToSuperview(safeArea: false)
        web.loadRequest()
        web.registerMessageHandlers()
        return collectionViewContainer;
    }
    
    @objc private func onReceiveNotification(notify: Notification) {
        if let notifyName = notify.userInfo?["notifyName"] as? String, notifyName == "DeviceMemberChanged" {
            reloadMembers()
        }
    }
    
    func reloadMembers() {
        deviceMemberWebView?.reload()
    }
    
    func deviceBatteryView(_ device: CHDevice) -> CHUIArrowSettingView {
        let batteryView = CHUIViewGenerator.arrow() { [unowned self] sender,event in
            navigationController?.pushViewController(CHWebViewController.instanceWithScene("battery-trend", extInfo: [
                "deviceUUID": device.deviceId.uuidString,
                "deviceName": "\(device.deviceName)"
            ]), animated: true)
        }
        batteryView.title = "co.candyhouse.sesame2.battery".localized
        batteryView.value = device.batteryPercentage().map { "\($0)%" } ?? ""
        return batteryView
    }
}

// HomePage Popup
extension CHBaseViewController {
    func setNavigationItemRightMenu() {
        let copyAction = UIAction(
            title: "co.candyhouse.sesame2.NewSesame".localized,
            image: UIImage.SVGImage(named: "cube", fillColor: .black),
            identifier: UIAction.Identifier("new-device")
        ) { [weak self] action in
            self?.onMenuItemClick(action)
        }
        
        let shareAction = UIAction(
            title: "co.candyhouse.sesame2.scanQRCode".localized,
            image: UIImage.SVGImage(named: "qr-code-scan", fillColor: .black),
            identifier: UIAction.Identifier("scan-qrcode")
        ) { [weak self] action in
            self?.onMenuItemClick(action)
        }
        
        let editAction = UIAction(
            title: "co.candyhouse.sesame2.AddContacts".localized,
            image: UIImage.SVGImage(named: "find_friend", fillColor: .black),
            identifier: UIAction.Identifier("add-friend")
        ) { [weak self] action in
            self?.onMenuItemClick(action)
        }
        let mainMenu = UIMenu(
            title: "",
            children: [copyAction, shareAction, editAction]
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage.SVGImage(named: "icons_outlined_addoutline"),
            menu: mainMenu
        )
    }
    
    private func onMenuItemClick(_ action: UIAction) {
        switch action.identifier.rawValue {
        case "new-device":
            presentRegisterSesame2ViewController()
        case "scan-qrcode":
            presentScanViewController()
        case "add-friend":
            navigationController?.pushViewController(FriendViewController.instanceWithFriendAdd(), animated: true)
        default:break;
            
        }
    }
}

extension CHBaseViewController {
    func setupBleTxPowerUIIfNeeded(in contentStackView: UIStackView, device: CHDevice) {
        guard bleTxPowerSliderView == nil else { return }
        
        var sliderView: CHUISliderSettingView!
        
        sliderView = CHUIViewGenerator.slider(
            defaultValue: bleTxPowerMinValue,
            maximumValue: bleTxPowerMaxValue,
            minimumValue: bleTxPowerMinValue,
            contentWidth: 240,
            { slider, event in
                guard let slider = slider as? UISlider else { return }
                let value = Int(round(slider.value))
                slider.value = Float(value)
                sliderView.updateBubble(withValue: "\(value) dBm")
            },
            { [weak self] slider, event in
                guard let self = self, let slider = slider as? UISlider else { return }
                let value = Int(round(slider.value))
                slider.value = Float(value)
                self.setBleTxPower(device: device, txPower: value)
            }
        )
        
        sliderView.title = "co.candyhouse.sesame2.BleTxPower".localized
        sliderView.slider.tintColor = .systemTeal
        sliderView.slider.thumbTintColor = .systemTeal
        sliderView.isSliderHidden = true
        sliderView.isHidden = true
        
        contentStackView.addArrangedSubview(sliderView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        bleTxPowerSliderView = sliderView
    }
    
    func showBleTxPowerUI(device: CHDevice, txPower: UInt8) {
        executeOnMainThread {
            guard let sliderView = self.bleTxPowerSliderView else { return }
            
            if txPower == self.bleTxPowerUnsetValue {
                sliderView.isHidden = true
                return
            }
            
            sliderView.isHidden = false
            sliderView.isSliderHidden = false
            
            let signedValue = Int(Int8(bitPattern: txPower))
            let clampedValue = min(max(signedValue, Int(self.bleTxPowerMinValue)), Int(self.bleTxPowerMaxValue))
            
            sliderView.slider.value = Float(clampedValue)
            sliderView.updateBubble(withValue: "\(clampedValue) dBm")
        }
    }
    
    func setBleTxPower(device: CHDevice, txPower: Int) {
        let raw = UInt8(bitPattern: Int8(txPower))
        device.setBleTxPower(txPower: raw) { result in
            switch result {
            case .success:
                L.d("BLE tx power", "set success: \(txPower) dBm")
            case .failure(let error):
                L.d("BLE tx power", "set failed: \(error.localizedDescription)")
            }
        }
    }
}
