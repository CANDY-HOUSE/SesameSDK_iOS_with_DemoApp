//
//  CHWebview+BLEConnect.swift
//  SesameUI
//
//  Created by eddy on 2025/12/11.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import SesameSDK
import Foundation
import UIKit

extension CHWebView {
    
    private struct WebAssociatedKeys {
        static var stateCallbackKey: UInt8 = 0
        static var ssidControllerKey: UInt8 = 1
    }
    
    var statuCallback: [String: String]? {
        get {
            return objc_getAssociatedObject(self, &WebAssociatedKeys.stateCallbackKey) as? [String: String]
        }
        set {
            objc_setAssociatedObject(self, &WebAssociatedKeys.stateCallbackKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var ssidScanViewController: WifiModule2SSIDScanViewController {
        get {
            return objc_getAssociatedObject(self, &WebAssociatedKeys.ssidControllerKey) as! WifiModule2SSIDScanViewController
        }
        set {
            objc_setAssociatedObject(self, &WebAssociatedKeys.ssidControllerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var currentViewController: UIViewController? {
        get {
            if let delegate = UIApplication.shared.delegate as? AppDelegate {
                return delegate.iterateViewControllers()
            }
            return nil
        }
    }
    
    var currentDevice: CHHub3? {
        get {
            var curDevice: CHHub3? = nil
            guard let statuCb = self.statuCallback else {
                return curDevice
            }
            CHDeviceManager.shared.getCHDevices { result in
                if case let .success(devices) = result {
                    guard let device = devices.data.first(where:  { statuCb["deviceUUID"] == $0.deviceId.uuidString }) else {
                        return
                    }
                    curDevice = (device as! CHHub3)
                }
            }
            return curDevice
        }
    }
    
    func registerBLEMessageHandlers() {
        registerMessageHandler(WebViewMessageType.requestBLEConnect.rawValue) { [self] webView, data in
            if let requestData = data as? [String: Any],
               let callbackName = requestData["callbackName"] as? String,
               let deviceUUID = requestData["deviceUUID"] as? String {
                self.statuCallback = [
                    "deviceUUID": deviceUUID,
                    WebViewMessageType.requestBLEConnect.rawValue: callbackName
                ]
                guard let device = currentDevice else { return }
                device.delegate = self
                if device.deviceStatus.loginStatus == .logined {
                    callH5(funcName: callbackName, data: ["bleStatus": device.deviceStatus.loginStatus.rawValue])
                    return
                }
                if !device.isBleAvailable() {
                    callH5(funcName: callbackName, data: ["bleStatus": "co.candyhouse.sesame2.bluetoothPoweredOff".localized])
                }
                L.d("Hub3 device id", device.deviceId.uuidString)
                device.connect { _ in }
            }
        }
        
        registerMessageHandler(WebViewMessageType.requestMonitorInternet.rawValue) { [self] webView, data in
            if let requestData = data as? [String: Any],
               let callbackName = requestData["callbackName"] as? String {
                self.statuCallback![WebViewMessageType.requestMonitorInternet.rawValue] = callbackName
                L.d("Hub3 requestMonitorInternet", self.statuCallback as Any)
            }
        }
        
        registerMessageHandler(WebViewMessageType.requestConfigureInternet.rawValue) { [self] webView, data in
            if let _ = data as? [String: Any] {
                guard let vc = currentViewController else { return }
                self.ssidScanViewController = WifiModule2SSIDScanViewController.instance()
                self.ssidScanViewController.delegate = self
                vc.present(self.ssidScanViewController.navigationController!, animated: true, completion: nil)
            }
        }
        
    }
    
    func destroyBLEConnets() {
        guard let device = currentDevice else { return }
        device.delegate = nil
        device.disconnect { _ in }
        self.statuCallback = nil
    }
}

//MARK: Utils
extension CHWebView {
    private func setWifiPasswordAndConnect(_ password: String) {
        executeOnMainThread {
            ViewHelper.showLoadingInView(view: self.ssidScanViewController.view)
        }
        let device = currentDevice!
        device.setWifiPassword(password) { setPasswordResult in
            if case let .failure(error) = setPasswordResult {
                executeOnMainThread {
                    self.ssidScanViewController.view.makeToast("\(error.errorDescription())")
                    ViewHelper.hideLoadingView(view: self.ssidScanViewController.view)
                }
            } else {
                executeOnMainThread {
                    self.ssidScanViewController.dismiss(animated: true, completion: {
                        device.connectWifi { connectWifiResult in
                            if case .failure(_) = connectWifiResult {
                                executeOnMainThread { [self] in
                                    guard let vc = currentViewController else { return }
                                    let alertController = UIAlertController(title: "", message: "co.candyhouse.sesame2.connectWifiFailed".localized, preferredStyle: .alert)
                                    alertController.addAction(.init(title: "co.candyhouse.sesame2.OK".localized, style: .default, handler: nil))
                                    vc.present(alertController, animated: true, completion: {})
                                }
                            }
                        }
                    })
                }
            }
        }
    }
}

extension CHWebView: WifiModule2SSIDScanViewControllerDelegate {
    
    func onSSIDSelected(_ ssid: String) {
        ViewHelper.showLoadingInView(view: self.ssidScanViewController.view)
        currentDevice!.setWifiSSID(ssid) { setResult in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.ssidScanViewController.view)
                if case let .failure(error) = setResult {
                    self.ssidScanViewController.view.makeToast(error.errorDescription())
                } else {
                    var pwd = ""
#if DEBUG
                    pwd = "55667788"
#endif
                    self.ssidScanViewController
                        .navigationController?
                        .presentCHAlertWithPlaceholder(title: ssid,
                                                       placeholder: pwd,
                                                       hint: "co.candyhouse.sesame2.enterSSIDPassword".localized) { password in
                            self.setWifiPasswordAndConnect(password)
                        }
                }
            }
        }
    }
    
    func onScanRequested() {
        executeOnMainThread { [self] in
            guard let device = currentDevice else { return }
            device.scanWifiSSID { _ in }
        }
    }
}

extension CHWebView: CHDeviceStatusAndKeysDelegate {
    
    // MARK: CHDeviceStatusDelegate
    func onMechStatus(device: CHDevice) {
        guard let statuCb = self.statuCallback,
              let cbName = statuCb[WebViewMessageType.requestMonitorInternet.rawValue],
              let networkStatus = (device.mechStatus as? CHWifiModule2NetworkStatus) else { return }
        callH5(funcName: cbName, data: [
            "op": "onMechStatus",
            "isAPWork": networkStatus.isAPWork == true ? true : false,
            "isNetwork": networkStatus.isNetwork == true ? true : false,
            "isIoTWork": networkStatus.isIoTWork == true ? true : false,
            "isBindingAPWork": networkStatus.isBindingAPWork,
            "isConnectingNetwork": networkStatus.isConnectingNetwork,
            "isConnectingIoT": networkStatus.isConnectingIoT
        ])
    }
    
    func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus,shadowStatus:CHDeviceStatus?) {
        if status == .receivedBle() {
            // 【eddy todo】点 ota升级时，硬件重启第一次立即连接时，会出现连接异常[硬件已经被连接上，但实际app的登录没有返回]，延时1s解决
            Debouncer(interval: 1.0).debounce { [weak self] in
                guard let _ = self else { return }
                device.connect() { _ in }
            }
        }
        executeOnMainThread { [self] in
            guard let statuCb = self.statuCallback, let cbName = statuCb[WebViewMessageType.requestBLEConnect.rawValue] else { return }
            callH5(funcName: cbName, data: ["bleStatus": device.deviceStatus.loginStatus == .logined ? device.deviceStatus.loginStatus.rawValue : device.localizedDescription()])
        }
    }
    
    // MARK: CHWifiModule2Delegate
    func onSesame2KeysChanged(device: any SesameSDK.CHWifiModule2, sesame2keys: [String : String]) {
        L.d("onSesame2KeysChanged", sesame2keys);
    }
    
    func onScanWifiSID(device: any CHWifiModule2, ssid: CHSSID) {
        executeOnMainThread { [weak self] in
            guard let self = self else { return }
            if self.ssidScanViewController.ssids.contains(ssid) == false {
                self.ssidScanViewController.ssids.append(ssid)
            } else if let oldSSID = self.ssidScanViewController.ssids.filter({ $0 == ssid }).first, ssid.rssi > oldSSID.rssi {
                self.ssidScanViewController.ssids.removeAll(where: { $0 == ssid })
                self.ssidScanViewController.ssids.append(ssid)
            }
            if let settingSSID = device.mechSetting?.wifiSSID {
                self.ssidScanViewController.ssids = self.ssidScanViewController.ssids.sorted { left, right -> Bool in
                    if left.name == settingSSID {
                        return true
                    } else if right.name == settingSSID {
                        return false
                    } else {
                        return left.rssi > right.rssi
                    }
                }
            }
            self.ssidScanViewController.reloadTableView()
        }
    }
    
    func onAPSettingChanged(device: CHWifiModule2, settings: CHWifiModule2MechSettings) {
        guard let mechSetting = device.mechSetting else { return }
        executeOnMainThread { [self] in
            guard let statuCb = self.statuCallback, let cbName = statuCb[WebViewMessageType.requestMonitorInternet.rawValue] else { return }
            callH5(funcName: cbName, data: [
                "op": "onAPSettingChanged",
                "wifiSsid": mechSetting.wifiSSID,
                "wifiPwd": mechSetting.wifiPassword
            ])
        }
    }
}
