//
//  CHWebHostViewController+BLEConnect.swift
//  SesameUI
//
//  Hub3 BLE 配网能力：由承载页（VC）持有设备回调与 SSID 扫描页，
//  H5 通过 bridge 触发连接 / 配网 / 固件升级。
//
//  Created by eddy on 2025/12/11.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import SesameSDK
import Foundation
import UIKit

extension CHWebHostViewController {

    private struct BLEAssociatedKeys {
        static var statusCallback: UInt8 = 0
    }

    /// H5 各 BLE 请求的回调名
    var bleStatusCallback: [String: String]? {
        get { objc_getAssociatedObject(self, &BLEAssociatedKeys.statusCallback) as? [String: String] }
        set { objc_setAssociatedObject(self, &BLEAssociatedKeys.statusCallback, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /// 正在展示的 SSID 扫描页：由展示层级推导，无需存储属性
    var ssidScanViewController: WifiModule2SSIDScanViewController? {
        (presentedViewController as? UINavigationController)?
            .viewControllers.first as? WifiModule2SSIDScanViewController
    }

    private var currentDevice: CHHub3? {
        var curDevice: CHHub3? = nil
        guard let statuCb = bleStatusCallback else {
            return curDevice
        }
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                guard let device = devices.data.first(where: { statuCb["deviceUUID"] == $0.deviceId.uuidString }) else {
                    return
                }
                curDevice = (device as! CHHub3)
            }
        }
        return curDevice
    }

    /// 注册 Hub3 BLE 配网能力（通过承载页的通用扩展点接入，并自行登记销毁清理）
    func registerBLEMessageHandlers(on web: CHWebView) {
        addDestroyPageHandler { host in host.destroyBLEConnects() }

        web.registerMessageHandler(WebViewMessageType.requestBLEConnect.rawValue) { [weak self] webView, data in
            guard let self = self else { return }
            if let requestData = data as? [String: Any],
               let callbackName = requestData["callbackName"] as? String,
               let deviceUUID = requestData["deviceUUID"] as? String {
                self.bleStatusCallback = [
                    "deviceUUID": deviceUUID,
                    WebViewMessageType.requestBLEConnect.rawValue: callbackName
                ]
                guard let device = self.currentDevice else { return }
                device.delegate = self
                if device.deviceStatus.loginStatus == .logined {
                    webView.callH5(funcName: callbackName, data: ["bleStatus": device.deviceStatus.loginStatus.rawValue])
                    return
                }
                let r = device.isBleAvailable(withHint: ())
                if let key = r.hintKey {
                    webView.callH5(funcName: callbackName, data: ["bleStatus": key.localized])
                }
                L.d("Hub3 device id", device.deviceId.uuidString)
                device.connect { _ in }
            }
        }

        web.registerMessageHandler(WebViewMessageType.requestMonitorInternet.rawValue) { [weak self] _, data in
            guard let self = self else { return }
            if let requestData = data as? [String: Any],
               let callbackName = requestData["callbackName"] as? String {
                self.bleStatusCallback?[WebViewMessageType.requestMonitorInternet.rawValue] = callbackName
                L.d("Hub3 requestMonitorInternet", self.bleStatusCallback as Any)
            }
        }

        web.registerMessageHandler(WebViewMessageType.requestConfigureInternet.rawValue) { [weak self] _, data in
            guard let self = self else { return }
            if let _ = data as? [String: Any] {
                let scanVC = WifiModule2SSIDScanViewController.instance()
                scanVC.delegate = self
                guard let nav = scanVC.navigationController else { return }
                self.present(nav, animated: true, completion: nil)
            }
        }

        web.registerMessageHandler(WebViewMessageType.requestDeviceFWUpgrade.rawValue) { [weak self] _, data in
            guard let self = self else { return }
            if let requestData = data as? [String: Any],
               let callbackName = requestData["callbackName"] as? String {
                self.bleStatusCallback?[WebViewMessageType.requestDeviceFWUpgrade.rawValue] = callbackName
                guard let device = self.currentDevice else { return }
                device.updateFirmware { _ in }
            }
        }
    }

    func destroyBLEConnects() {
        guard let device = currentDevice else { return }
        device.delegate = nil
        device.disconnect { _ in }
        bleStatusCallback = nil
    }
}

//MARK: Utils
extension CHWebHostViewController {
    private func setWifiPasswordAndConnect(_ password: String) {
        guard let scanVC = ssidScanViewController, let device = currentDevice else { return }
        executeOnMainThread {
            ViewHelper.showLoadingInView(view: scanVC.view)
        }
        device.setWifiPassword(password) { setPasswordResult in
            if case let .failure(error) = setPasswordResult {
                executeOnMainThread {
                    scanVC.view.makeToast("\(error.errorDescription())")
                    ViewHelper.hideLoadingView(view: scanVC.view)
                }
            } else {
                executeOnMainThread {
                    scanVC.dismiss(animated: true, completion: {
                        device.connectWifi { connectWifiResult in
                            if case .failure(_) = connectWifiResult {
                                executeOnMainThread { [weak self] in
                                    guard let self = self else { return }
                                    let alertController = UIAlertController(title: "", message: "co.candyhouse.sesame2.connectWifiFailed".localized, preferredStyle: .alert)
                                    alertController.addAction(.init(title: "co.candyhouse.sesame2.OK".localized, style: .default, handler: nil))
                                    self.present(alertController, animated: true, completion: {})
                                }
                            }
                        }
                    })
                }
            }
        }
    }
}

extension CHWebHostViewController: WifiModule2SSIDScanViewControllerDelegate {

    func onSSIDSelected(_ ssid: String) {
        guard let scanVC = ssidScanViewController, let device = currentDevice else { return }
        ViewHelper.showLoadingInView(view: scanVC.view)
        device.setWifiSSID(ssid) { setResult in
            executeOnMainThread { [weak self] in
                guard let self = self else { return }
                ViewHelper.hideLoadingView(view: scanVC.view)
                if case let .failure(error) = setResult {
                    scanVC.view.makeToast(error.errorDescription())
                } else {
                    var pwd = ""
#if DEBUG
                    pwd = "55667788"
#endif
                    scanVC.navigationController?
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
        executeOnMainThread { [weak self] in
            guard let self = self, let device = self.currentDevice else { return }
            device.scanWifiSSID { _ in }
        }
    }
}

extension CHWebHostViewController: CHDeviceStatusAndKeysDelegate, CHWifiModule2Delegate {

    // MARK: CHDeviceStatusDelegate
    func onMechStatus(device: CHDevice) {
        guard let statuCb = bleStatusCallback,
              let cbName = statuCb[WebViewMessageType.requestMonitorInternet.rawValue],
              let networkStatus = (device.mechStatus as? CHWifiModule2NetworkStatus) else { return }
        webView?.callH5(funcName: cbName, data: [
            "op": "onMechStatus",
            "isAPWork": networkStatus.isAPWork == true ? true : false,
            "isNetwork": networkStatus.isNetwork == true ? true : false,
            "isIoTWork": networkStatus.isIoTWork == true ? true : false,
            "isBindingAPWork": networkStatus.isBindingAPWork,
            "isConnectingNetwork": networkStatus.isConnectingNetwork,
            "isConnectingIoT": networkStatus.isConnectingIoT
        ])
    }

    func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus, shadowStatus: CHDeviceStatus?) {
        if status == .receivedBle() {
            // 【eddy todo】点 ota升级时，硬件重启第一次立即连接时，会出现连接异常[硬件已经被连接上，但实际app的登录没有返回]，延时1s解决
            Debouncer(interval: 1.0).debounce { [weak self] in
                guard let _ = self else { return }
                device.connect() { _ in }
            }
        }
        executeOnMainThread { [weak self] in
            guard let self = self,
                  let statuCb = self.bleStatusCallback,
                  let cbName = statuCb[WebViewMessageType.requestBLEConnect.rawValue] else { return }
            self.webView?.callH5(funcName: cbName, data: ["bleStatus": device.deviceStatus.loginStatus == .logined ? device.deviceStatus.loginStatus.rawValue : device.localizedDescription()])
        }
    }

    // MARK: CHWifiModule2Delegate
    func onSesame2KeysChanged(device: any SesameSDK.CHWifiModule2, sesame2keys: [String : String]) {
        L.d("onSesame2KeysChanged", sesame2keys);
    }

    func onOTAProgress(device: CHWifiModule2, percent: UInt8) {
        guard let statuCb = bleStatusCallback, let cbName = statuCb[WebViewMessageType.requestDeviceFWUpgrade.rawValue] else { return }
        L.d("onOTAProgress", percent)
        if percent % 10 == 0 {
            webView?.callH5(funcName: cbName, data: ["deviceUUID": device.deviceId.uuidString, "percent": "\(percent)"])
        }
    }

    func onScanWifiSID(device: any CHWifiModule2, ssid: CHSSID) {
        executeOnMainThread { [weak self] in
            guard let self = self, let scanVC = self.ssidScanViewController else { return }
            if scanVC.ssids.contains(ssid) == false {
                scanVC.ssids.append(ssid)
            } else if let oldSSID = scanVC.ssids.filter({ $0 == ssid }).first, ssid.rssi > oldSSID.rssi {
                scanVC.ssids.removeAll(where: { $0 == ssid })
                scanVC.ssids.append(ssid)
            }
            if let settingSSID = device.mechSetting?.wifiSSID {
                scanVC.ssids = scanVC.ssids.sorted { left, right -> Bool in
                    if left.name == settingSSID {
                        return true
                    } else if right.name == settingSSID {
                        return false
                    } else {
                        return left.rssi > right.rssi
                    }
                }
            }
            scanVC.reloadTableView()
        }
    }

    func onAPSettingChanged(device: CHWifiModule2, settings: CHWifiModule2MechSettings) {
        guard let mechSetting = device.mechSetting else { return }
        executeOnMainThread { [weak self] in
            guard let self = self,
                  let statuCb = self.bleStatusCallback,
                  let cbName = statuCb[WebViewMessageType.requestMonitorInternet.rawValue] else { return }
            self.webView?.callH5(funcName: cbName, data: [
                "op": "onAPSettingChanged",
                "wifiSsid": mechSetting.wifiSSID,
                "wifiPwd": mechSetting.wifiPassword
            ])
        }
    }
}
