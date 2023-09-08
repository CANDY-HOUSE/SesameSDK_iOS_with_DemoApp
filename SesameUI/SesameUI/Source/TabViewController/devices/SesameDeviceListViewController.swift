
// SesameDeviceListViewController.swift

import UIKit
import SesameSDK

class SesameDeviceListViewController: CHBaseTableVC {
    var devices: [CHDevice] = []
    var reorderTableView: LongPressReorderTableView!
    var refreshControl: UIRefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: "icons_outlined_addoutline"),style: .done, target: self, action: #selector(handleRightBarButtonTapped(_:)))

        if(UserDefaults.standard.bool(forKey: "refreshDevice") == true){/// 根据推送决定要不要刷新设备
            UserDefaults.standard.set(false, forKey: "refreshDevice")
        }

        tableView.separatorStyle = .none
        tableView.refreshControl = refreshControl
        tableView.register(UINib(nibName: "Sesame5ListCell", bundle: nil),forCellReuseIdentifier: "Sesame5ListCell")
        tableView.register(UINib(nibName: "WifiModule2ListCell", bundle: nil),forCellReuseIdentifier: "WifiModule2ListCell")
        setupEmptyDataView("co.candyhouse.sesame2.NoDevices".localized)

        reorderTableView = LongPressReorderTableView(tableView,selectedRowScale: .big)
        reorderTableView.delegate = self
        reorderTableView.enableLongPressReorder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getKeysFromCache()
    }
    
    func getKeysFromCache() {
        CHDeviceManager.shared.getCHDevices { getResult in
            switch getResult {
            case .success(let devices):
                self.devices = devices.data.sorted { left, right -> Bool in
                    left.compare(right)// 排序
                }
                executeOnMainThread {
                    self.refreshControl.endRefreshing()
                    self.reloadTableView()
                }
            case .failure(let error):
                executeOnMainThread {
                    self.view.makeToast(error.errorDescription())
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        devices.count
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {}
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {}
    
    
    // MARK: ListCell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        let device = devices[indexPath.row]
        if let wifiModule2 = device as? CHWifiModule2 {
            cell = tableView.dequeueReusableCell(withIdentifier: "WifiModule2ListCell", for: indexPath)
            let wifiModule2Cell = cell as! WifiModule2ListCell
            wifiModule2Cell.wifiModule2 = wifiModule2
        } else   {
            cell = tableView.dequeueReusableCell(withIdentifier: "Sesame5ListCell", for: indexPath)
            let ss5Cell = cell as! Sesame5ListCell
            ss5Cell.device = device
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
       
        let device = devices[indexPath.row]

        if let sesame2 = device as? CHSesame2 {
            if sesame2.keyLevel == KeyLevel.guest.rawValue {
                navigateToSesame2Setting(sesame2)
            } else {
                navigateToSesame2History(sesame2)
            }
        }else if let sesame5 = device as? CHSesame5 {
            if sesame5.keyLevel == KeyLevel.guest.rawValue {
                navigateToSesame5Setting(sesame5)
            } else {
                navigateToSesame5History(sesame5)
            }
        } else if let sesameBot = device as? CHSesameBot {
            navigateToSesameBotSettingViewController(sesameBot)
        } else if let bikeLock = device as? CHSesameBike {
            navigateToBikeLockSettingViewController(bikeLock)
        } else if let wifiModule2 = device as? CHWifiModule2 {
            navigateToWifiModule2SettingViewController(wifiModule2)
        } else if let device = device as? CHSesameTouchPro {
            if(device.productModel == .openSensor){
                navigateToOpenSensorResetVC(device)
            }else if(device.productModel == .bleConnector){
                navigateToBleConnectorVC(device)
            }else{
                navigateToCHSesameTouchProSettingVC(device)
            }
        } else if let bikeLock2 = device as? CHSesameBike2 {
            navigateToBike2SettingViewController(bikeLock2)
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

extension SesameDeviceListViewController { // 設備列表排序
    override func positionChanged(currentIndex: IndexPath, newIndex: IndexPath) {
        let movedObject = devices[currentIndex.row]
        devices.remove(at: currentIndex.row)
        devices.insert(movedObject, at: newIndex.row)
    }
}
