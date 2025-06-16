
// SesameDeviceListViewController.swift

import UIKit
import SesameSDK
import AWSMobileClientXCF

class SesameDeviceListViewController: CHBaseViewController {
    var devices: [CHDevice] = []
    var reorderTableView: LongPressReorderTableView!
    var tableViewProxy: CHTableViewProxy!
    var isDraggingCell = false
    let debouncer = Debouncer(interval: 0.5)

//    var mUserState: UserState = AWSMobileClient.default().currentUserState { // 這行要留著
    
    func reloadTableView() {
        tableViewProxy.reload()
    }
    
    func refreshData() {
        getKeysFromCache()
    }
    
    override func didBecomeActive() {
        checkIfNeedsRefresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkIfNeedsRefresh()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: "icons_outlined_addoutline"),style: .done, target: self, action: #selector(handleRightBarButtonTapped(_:)))

        // 應先同步 app & aws 的狀態到一致
        monitorAWSMobileClientUserState()
        configureTable()
        checkIfNeedsRefresh()
    }
    
    func checkIfNeedsRefresh() {
        guard self.isViewLoaded else { return }
        if UserDefaults.standard.bool(forKey: "refreshDevice") {/// 根据推送决定要不要刷新设备
            UserDefaults.standard.set(false, forKey: "refreshDevice")
            self.refreshData()
            self.getKeysFromServer()
        }
    }
    
    func monitorAWSMobileClientUserState() {
        let statusChangeHandler: (_ state: AWSMobileClientXCF.UserState) -> Void = { state in
            if (state == .signedIn) {
                //                    L.d("[mUserState] => signedIn")
                CHUserAPIManager.shared.getSubId { subId in
                    guard let subId = subId else { return }
                    let newKeys = CHUserAPIManager.shared.getLocalUserKeys().map { (userKey: CHUserKey) -> CHUserKey in
                        var userKey = userKey
                        userKey.subUUID = subId
                        return userKey
                    }
                    CHUserAPIManager.shared.postCHUserKeys(newKeys) { result in
                        // 如果上傳UserKeys失敗時跳出提示訊息
                        CHDeviceManager.shared.setHistoryTag()
                        self.getKeysFromServer()
                    }
                }
            }
            else if (state == .signedOut) {
                L.d("[mUserState] => signedOut")
                executeOnMainThread {
                    CHDeviceManager.shared.dropAllLocalKeys() {
                        Sesame2Store.shared.setHistoryTag("\("co.candyhouse.sesame2.unknownUser".localized)") // 偏好設定檔的historyTag
                        WatchKitFileTransfer.shared.transferKeysToWatch()
                        self.getKeysFromCache()
                    }
                }
            } else { L.d("[mUserState]=>??", state)}
        }
        AWSMobileClient.default().addUserStateListener(self) { state, dic in
            L.d("[mUserState][listener]",state)
            statusChangeHandler(state)
        }
    }
    
    func configureTable() {
        tableViewProxy = CHTableViewProxy(superView: self.view, selectHandler: { [self] it , indxPath  in
            if it.rawValue is CHDevice {
                self.handleSelectDeviceItem(it.rawValue as! CHDevice, indxPath)
            } else {
                guard let remote = it.rawValue as? IRRemote else { return }
                let device = devices.first { device in
                    if let hub3Device = device as? CHHub3 {
                        return hub3Device.irRemotes.contains { $0.uuid == remote.uuid }
                    }
                    return false
                }
                if let device = device {
                    device.preference.updateSelectExpandIndex(((device as! CHHub3).irRemotes.firstIndex(where: { $0.uuid == remote.uuid }))!)
                    switch remote.type {
                    case IRDeviceType.DEVICE_REMOTE_CUSTOM:
                        self.present(UINavigationController(rootViewController: Hub3IRCustomizeControlVC.instance(device: (device as! CHHub3))), animated: true)
                        break
                    case IRDeviceType.DEVICE_REMOTE_AIR, IRDeviceType.DEVICE_REMOTE_TV, IRDeviceType.DEVICE_REMOTE_LIGHT:
                        let handler = IRDeviceType.controlFactory(remote.type, remote.state)
                        let vc = Hub3IRRemoteControlVC(irRemote: remote)
                        vc.chDevice = (device as! CHHub3)
                        self.present(UINavigationController(rootViewController: vc), animated: true)
                        break
                    default: break
                    }
                }
            }
        } ,emptyPlaceholder: "co.candyhouse.sesame2.NoDevices".localized)
        tableViewProxy.configureTableHeader({
            self.getKeysFromServer()
        }, nil)
        reorderTableView = LongPressReorderTableView(tableViewProxy.tableView,selectedRowScale: .big)
        reorderTableView.delegate = self
        reorderTableView.enableLongPressReorder()
    }
    
    @objc func getKeysFromServer() {
        if AWSMobileClient.default().currentUserState == .signedIn {
            CHUserAPIManager.shared.getCHUserKeys { result in
                L.d("[DeviceList][登入][登出]getKeysFromServer")
                if case let .failure(error) = result {
                    executeOnMainThread {
                        self.tableViewProxy.handleFailedDataSource(error)
                    }
                } else if case let .success(userKeys) = result  {
                    let nickname = CHUserAPIManager.shared.getNickname { _ in }
                    Sesame2Store.shared.setHistoryTag(nickname)
                    CHDeviceManager.shared.setHistoryTag()
                    for userKey in userKeys.data {
//                        L.d("[DeviceList][登出]刷新列表FromServer",userKey.deviceName,userKey.deviceModel,userKey.keyLevel)
                        let device = userKey.toCHDevice()
                        if let keyLevel = userKey.keyLevel {
                            device?.setKeyLevel(keyLevel)
                        }
                        if let deviceName = userKey.deviceName {
                            device?.setDeviceName(deviceName)
                        }
                        if let rank = userKey.rank {
                            device?.setRank(level: rank)
                        }
                    }
                    WatchKitFileTransfer.shared.transferKeysToWatch()
                    self.getKeysFromCache()
                }
            }
        } else {
            WatchKitFileTransfer.shared.transferKeysToWatch()
            self.getKeysFromCache()
        }
    }
    
    func getKeysFromCache() {
        CHDeviceManager.shared.getCHDevices { [unowned self] getResult in
            L.d("[DeviceList][登入][登出]getKeysFromCache")
            switch getResult {
            case .success(let devices):
                self.devices = devices.data.sorted { left, right -> Bool in
                    left.compare(right)// 排序
                }
                for (index, device) in self.devices.enumerated() {
                    print("Device[\(index)]: name=\(device.deviceName ?? "Unknown"), id=\(device.deviceId?.uuidString ?? "Unknown")")
                    if let productModel = device.productModel {
                        print("    Model: \(productModel), ModelName: \(productModel.deviceModelName())")
                    }
                }
                self.rebuildData()
            case .failure(let error):
                executeOnMainThread {
                    self.view.makeToast(error.errorDescription())
                }
            }
        }
    }

    func handleSelectDeviceItem(_ device: CHDevice, _ indexPath: IndexPath) {
        switch device.productModel! {
        case .sesame2, .sesame4:
            guard let sesame2 = device as? CHSesame2 else { return }
            if sesame2.keyLevel == KeyLevel.guest.rawValue {
                navigateToSesame2Setting(sesame2)
            } else {
                navigateToSesame2History(sesame2)
            }
        case .sesame5, .sesame5Pro, .sesame5US:
            guard let sesame5 = device as? CHSesame5 else { return }
            if sesame5.keyLevel == KeyLevel.guest.rawValue {
                navigateToSesame5Setting(sesame5)
            } else {
                navigateToSesame5History(sesame5)
            }
        case .sesameBot:
            guard let sesameBot = device as? CHSesameBot else { return }
            navigateToSesameBotSettingViewController(sesameBot)
        case .sesameBot2:
            guard let bot2Device = device as? CHSesameBot2 else { return }
            navigateToBot2SettingViewController(bot2Device)
            DispatchQueue.main.async { [weak self] in
                if device.preference.expanded {
                    self?.toggleIndexPathForHub3(device, true)
                }
            }
        case .bikeLock:
            guard let bikeLock = device as? CHSesameBike else { return }
            navigateToBikeLockSettingViewController(bikeLock)
        case .bikeLock2:
            guard let bikeLock2 = device as? CHSesameBike2 else { return }
            navigateToBike2SettingViewController(bikeLock2)
        case .hub3:
            guard let hub3 = device as? CHHub3 else { return }
            navigateToHub3SettingViewController(hub3)
            DispatchQueue.main.async { [weak self] in
                if hub3.preference.expanded {
                    self?.toggleIndexPathForHub3(hub3, true)
                }
            }
        case .wifiModule2:
            guard let wifiModule2 = device as? CHWifiModule2 else { return }
            navigateToWifiModule2SettingViewController(wifiModule2)
        case .openSensor, .remoteNano:
            guard let device = device as? CHSesameTouchPro else { return }
            navigateToOpenSensorResetVC(device)
        case .bleConnector, .remote:
            guard let device = device as? CHSesameTouchPro else { return }
            navigateToBleConnectorVC(device)
        case .sesameTouchPro:
            guard let device = device as? CHSesameTouchPro else { return }
            navigateToCHSesameBiometricSettingVC(device)
        case .sesameTouch:
            guard let device = device as? CHSesameTouch else { return }
            navigateToCHSesameBiometricSettingVC(device)
        case .sesameFacePro:
            guard let device = device as? CHSesameFacePro else { return }
            navigateToCHSesameBiometricSettingVC(device)
        case .sesameFace:
            guard let device = device as? CHSesameFace else { return }
            navigateToCHSesameBiometricSettingVC(device)
        }
    }
}

extension SesameDeviceListViewController {
    static func instance() -> SesameDeviceListViewController {
        let vc = SesameDeviceListViewController(nibName: nil, bundle: nil)
        let nv = UINavigationController()
        nv.pushViewController(vc, animated: false)
        return vc
    }
}
