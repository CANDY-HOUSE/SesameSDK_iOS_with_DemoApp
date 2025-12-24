
// SesameDeviceListViewController.swift

import UIKit
import SesameSDK
import AWSMobileClientXCF
import SafariServices
import SwiftUI
import Combine

class SesameDeviceListViewController: CHBaseViewController {
    var devices: [CHDevice] = []
    var reorderTableView: LongPressReorderTableView!
    var tableViewProxy: CHTableViewProxy!
    private var lastUserState = UserState.unknown

    var isDraggingCell = false
    let debouncer = Debouncer(interval: 0.5)
    // 搜索框相关属性
    var searchBar: UISearchBar!
    var searchBarContainer: UIView!
    var searchBarTopConstraint: NSLayoutConstraint!
    let searchBarHeight: CGFloat = 56
    private var lastContentOffset: CGFloat = 0
    private var isInitialLoading = true
    private var isAnimatingSearchBar = false
    private var allDevices: [CHDevice] = []
    private var lastSearchQuery = ""
    
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
        setNavigationItemRightMenu()
        
        // 應先同步 app & aws 的狀態到一致
        monitorAWSMobileClientUserState()
        configureTable()
        
        // 确保搜索框初始隐藏
        view.layoutIfNeeded()
        searchBarTopConstraint.constant = -searchBarHeight
        
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
        let statusChangeHandler: (_ state: AWSMobileClientXCF.UserState) -> Void = { [self] state in
            if (state == .signedIn) {
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
                guard lastUserState == .signedIn else { return }
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
            self.lastUserState = state
        }
        self.lastUserState = AWSMobileClient.default().currentUserState
    }
    
    func configureTable() {
        tableViewProxy = CHTableViewProxy(superView: self.view, selectHandler: { [self] it , indxPath  in
            if it.rawValue is CHDevice {
                self.handleSelectDeviceItem(it.rawValue as! CHDevice, indxPath)
            } else {
                guard let remote = it.rawValue as? IRRemote else { return }
                let device = devices.first { device in
                    if let hub3Device = device as? CHHub3 {
                        return ((hub3Device.stateInfo?.remoteList?.first(where: { $0.uuid == remote.uuid })) != nil)
                    }
                    return false
                }
                let remoteString = try! JSONEncoder().encode(remote)
                let extInfo: [String: String] = [
                    "irRemote": String(data: remoteString, encoding: .utf8) ?? "",
                    "deviceUUID": (device as! CHHub3).deviceId.uuidString.uppercased()
                ]
                navigationController?.pushViewController(CHWebViewController.instanceWithScene("ir-remote",extInfo:extInfo), animated:true)
            }
        } ,emptyPlaceholder: "co.candyhouse.sesame2.NoDevices".localized)
        
        searchBarContainer = UIView()
        searchBarContainer.backgroundColor = .systemBackground
        searchBarContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建搜索框
        searchBar = UISearchBar()
        searchBar.placeholder = "co.candyhouse.sesame2.search_devices".localized
        searchBar.delegate = self
        searchBar.showsCancelButton = false
        
        // 自定义搜索框样式
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .clear
        searchBar.barTintColor = .clear
        searchBar.isTranslucent = true
        
        // 自定义搜索文本框
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor(white: 0.97, alpha: 1.0) // 淡灰色背景
            textField.font = UIFont.systemFont(ofSize: 16)
            textField.layer.cornerRadius = 24
            textField.layer.masksToBounds = true
            textField.borderStyle = .none
            textField.layer.borderWidth = 0
        }
        
        // 移除所有默认图片
        searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        searchBar.setSearchFieldBackgroundImage(UIImage(), for: .normal)
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBarContainer.addSubview(searchBar)
        
        // 将搜索框容器添加到 view 上
        view.addSubview(searchBarContainer)
        
        // 设置搜索框在容器内的约束
        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: searchBarContainer.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: searchBarContainer.trailingAnchor, constant: -8),
            searchBar.topAnchor.constraint(equalTo: searchBarContainer.topAnchor),
            searchBar.bottomAnchor.constraint(equalTo: searchBarContainer.bottomAnchor)
        ])
        
        // 设置搜索框容器约束
        NSLayoutConstraint.activate([
            searchBarContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBarContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBarContainer.heightAnchor.constraint(equalToConstant: searchBarHeight)
        ])
        
        // 初始隐藏在导航栏上方
        searchBarTopConstraint = searchBarContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -searchBarHeight)
        searchBarTopConstraint.isActive = true
        
        // 初始时 tableView 不需要额外的 contentInset
        tableViewProxy.tableView.contentInset = UIEdgeInsets.zero
        if #available(iOS 13.0, *) {
            tableViewProxy.tableView.verticalScrollIndicatorInsets = .zero
        }
        
        // 下拉刷新配置
        tableViewProxy.configureTableHeader({
            self.getKeysFromServer()
        }, nil)
        
        // 滚动时自动收起键盘
        tableViewProxy.tableView.keyboardDismissMode = .onDrag
        
        reorderTableView = LongPressReorderTableView(tableViewProxy.tableView,selectedRowScale: .big)
        reorderTableView.delegate = self
        reorderTableView.enableLongPressReorder()
        
        // KVO监听tableView的滚动
        tableViewProxy.tableView.addObserver(self, forKeyPath: "contentOffset", options: [.new, .old], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentOffset", let scrollView = object as? UIScrollView {
            // 初始加载时或正在动画时不处理
            guard !isInitialLoading && !isAnimatingSearchBar else { return }
            
            // 初始加载时设备列表为空，不显示搜索框
            guard !devices.isEmpty else {
                lastContentOffset = scrollView.contentOffset.y
                return
            }
            
            let offsetY = scrollView.contentOffset.y
            let scrollDiff = offsetY - lastContentOffset
            
            // 如果是刷新控件或非用户操作，不处理
            if scrollView.isRefreshing || (!scrollView.isDragging && !scrollView.isDecelerating) {
                lastContentOffset = offsetY
                return
            }
            
            // 下拉显示搜索框
            if scrollDiff < -3 {
                showSearchBar()
            }
            // 上滑隐藏搜索框
            else if scrollDiff > 0 && offsetY > -10 {
                hideSearchBar()
            }
            
            lastContentOffset = offsetY
        }
    }
    
    private func showSearchBar() {
        guard searchBarTopConstraint.constant != 0 && !isAnimatingSearchBar else { return }
        
        isAnimatingSearchBar = true
        UIView.animate(withDuration: 0.3, animations: {
            self.searchBarTopConstraint.constant = 0
            self.view.layoutIfNeeded()
        }) { _ in
            UIView.animate(withDuration: 0.2, animations: {
                self.tableViewProxy.tableView.contentInset.top = self.searchBarHeight
                if #available(iOS 13.0, *) {
                    self.tableViewProxy.tableView.verticalScrollIndicatorInsets.top = self.searchBarHeight
                }
            }) { _ in
                self.isAnimatingSearchBar = false
                // 更新lastContentOffset，避免contentInset改变导致的偏移
                self.lastContentOffset = self.tableViewProxy.tableView.contentOffset.y
            }
        }
    }
    
    private func hideSearchBar() {
        guard searchBarTopConstraint.constant != -searchBarHeight && !isAnimatingSearchBar else { return }
        
        isAnimatingSearchBar = true
        UIView.animate(withDuration: 0.3, animations: {
            self.searchBarTopConstraint.constant = -self.searchBarHeight
            self.view.layoutIfNeeded()
        }) { _ in
            UIView.animate(withDuration: 0.2, animations: {
                self.tableViewProxy.tableView.contentInset.top = 0
                if #available(iOS 13.0, *) {
                    self.tableViewProxy.tableView.verticalScrollIndicatorInsets.top = 0
                }
            }) { _ in
                self.isAnimatingSearchBar = false
                // 更新lastContentOffset，避免contentInset改变导致的偏移
                self.lastContentOffset = self.tableViewProxy.tableView.contentOffset.y
            }
        }
    }
    
    deinit {
        tableViewProxy?.tableView.removeObserver(self, forKeyPath: "contentOffset")
    }
    
    @objc func getKeysFromServer() {
        let queryDevicesHandler: () -> Void = {
            CHUserAPIManager.shared.getCHUserKeys() { result in
                if case let .failure(error) = result {
                    executeOnMainThread {
                        self.tableViewProxy.handleFailedDataSource(error)
                    }
                } else if case let .success(userKeys) = result  {
                    let nickname = CHUserAPIManager.shared.getNickname { _ in }
                    Sesame2Store.shared.setHistoryTag(nickname)
                    CHDeviceManager.shared.setHistoryTag()
                    CHDeviceWrapperManager.shared.updateUserKeys(userKeys.data)
                    for userKey in userKeys.data {
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
        }
        if AWSMobileClient.default().currentUserState == .signedIn {
            queryDevicesHandler()
            return
        }
        let keychain = (ins: AWSUICKeyChainStore.instance(), key: "guestUploadDevice")
        if !keychain.ins.boolValue(forKey: keychain.key) {
            getKeysFromCache { devices in
                if devices.count < 1 {
                    keychain.ins.setBool(true, forKey: keychain.key)
                    return
                }
                CHUserAPIManager.shared.postCHUserKeys(devices.map { CHUserKey.fromCHDevice($0) }) { result in
                    if case .success(_) = result {
                        keychain.ins.setBool(true, forKey: keychain.key)
                    }
                }
            }
        } else {
            if NetworkReachabilityHelper.shared.isReachable {
                queryDevicesHandler()
            } else {
                NetworkReachabilityHelper.shared.addListener(self) { state in
                    if case .reachable(_) = state {
                        queryDevicesHandler()
                        NetworkReachabilityHelper.shared.removeListener(self)
                    }
                }
            }
        }
    }
    
    func getKeysFromCache(completion: (([CHDevice]) -> Void)? = nil) {
        CHDeviceManager.shared.getCHDevices { [unowned self] getResult in
            L.d("[DeviceList][登入][登出]getKeysFromCache")
            switch getResult {
            case .success(let devices):
                // 保存所有设备
                self.allDevices = devices.data.sorted { left, right -> Bool in
                    left.compare(right)
                }
                completion?(self.allDevices)
                // 如果有搜索词，重新过滤
                if !self.lastSearchQuery.isEmpty {
                    self.performSearch(query: self.lastSearchQuery)
                } else {
                    self.devices = self.allDevices
                    self.rebuildData()
                }
                
                // 数据加载完成后，设置标记
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isInitialLoading = false
                }
            case .failure(let error):
                executeOnMainThread {
                    self.view.makeToast(error.errorDescription())
                    self.isInitialLoading = false
                }
            }
        }
    }
    
    private func performSearch(query: String) {
        L.d("performSearch","keys = \(query)")
        
        if query.isEmpty {
            // 空查询，显示所有设备
            devices = allDevices
        } else {
            // 过滤设备（名称和UUID，忽略大小写）
            devices = allDevices.filter { device in
                let nameMatch = device.deviceName.localizedCaseInsensitiveContains(query)
                let uuidMatch = device.deviceId.uuidString.localizedCaseInsensitiveContains(query)
                return nameMatch || uuidMatch
            }
        }
        
        executeOnMainThread { [weak self] in
            self?.rebuildData()
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
        case .sesame5, .sesame5Pro, .sesame5US, .sesame6Pro, .bleConnector:
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
        case .remote:
            guard let device = device as? CHSesameTouchPro else { return }
            navigateToBleConnectorVC(device)
        case .sesameTouchPro:
            guard let device = device as? CHSesameTouchPro else { return }
            navigateToCHSesameBiometricSettingVC(device)
        case .sesameTouch2Pro:
            guard let device = device as? CHSesameTouchPro else { return }
            navigateToCHSesameBiometricSettingVC(device)
        case .sesameTouch:
            guard let device = device as? CHSesameTouch else { return }
            navigateToCHSesameBiometricSettingVC(device)
        case .sesameTouch2:
            guard let device = device as? CHSesameTouch else { return }
            navigateToCHSesameBiometricSettingVC(device)
        case .sesameFacePro:
            guard let device = device as? CHSesameFacePro else { return }
            navigateToCHSesameBiometricSettingVC(device)
        case .sesameFace2Pro:
            guard let device = device as? CHSesameFacePro else { return }
            navigateToCHSesameBiometricSettingVC(device)
        case .sesameFace:
            guard let device = device as? CHSesameFace else { return }
            navigateToCHSesameBiometricSettingVC(device)
        case .sesameFace2:
            guard let device = device as? CHSesameFace else { return }
            navigateToCHSesameBiometricSettingVC(device)
        case .sesameFaceAI:
            guard let device = device as? CHSesameFacePro else { return }
            navigateToCHSesameBiometricSettingVC(device)
        case .sesameFaceProAI:
            guard let device = device as? CHSesameFacePro else { return }
            navigateToCHSesameBiometricSettingVC(device)
        case .openSensor2:
            guard let device = device as? CHSesameTouchPro else { return }
            navigateToCHSesameBiometricSettingVC(device)
        }
    }
}

extension SesameDeviceListViewController: UISearchBarDelegate {
    
    static func instance() -> SesameDeviceListViewController {
        let vc = SesameDeviceListViewController(nibName: nil, bundle: nil)
        let nv = UINavigationController()
        nv.pushViewController(vc, animated: false)
        return vc
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let currentQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 避免重复搜索
        guard currentQuery != lastSearchQuery else { return }
        lastSearchQuery = currentQuery
        
        debouncer.debounce { [weak self] in
            self?.performSearch(query: currentQuery)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // 点击搜索按钮隐藏键盘
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        lastSearchQuery = ""
        performSearch(query: "")
    }
}
