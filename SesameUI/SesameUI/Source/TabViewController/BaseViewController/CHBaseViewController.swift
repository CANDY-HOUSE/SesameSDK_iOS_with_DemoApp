//
//  CHBaseVC.swift
//  sesame-sdk-test-app
//  [navigation views]
//  Created by tse on 2020/3/28.
//  Copyright © 2020 CandyHouse. All rights reserved.
//
import UIKit
import AVFoundation
import SesameSDK
import CoreBluetooth
import Foundation
import NordicDFU

public class CHBaseViewController: UIViewController, CHRouteCoordinator {
    // MARK: - Properties
    private var previouseNavigationTitle = ""
    
    public override var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    var soundPlayer: AVAudioPlayer?
    var navigationBarBackgroundColor: UIColor = .white
    private var isDfuActionLocked = false
    private var shouldRefreshVersionAfterDfu = false
    
    var bleTxPowerSliderView: CHUISliderSettingView?
    var bleTxPowerMinValue: Float { -4 }
    var bleTxPowerMaxValue: Float { 20 }
    var bleTxPowerUnsetValue: UInt8 { CHDeviceUnsetBleTxPowerValue }
    
    // MARK: - UI Components
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: .zero)
        view.addSubview(titleLabel)
        titleLabel.autoPinLeading()
        titleLabel.autoPinTrailing()
        titleLabel.autoPinCenterY()
        titleLabel.autoLayoutHeight(40)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.minimumScaleFactor = 0.01
        return titleLabel
    }()

    // MARK: - Life cycle
#if DEBUG
    deinit {
        L.d(" ===================== \(type(of: self)) deinit ===================== ")
    }
#endif
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        _ = BleHelper.shared // 初始化UI端的藍芽
        view.backgroundColor = .sesame2Gray
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance.shadowColor = .clear
        } else {
//            移除 navigation bar borders 的方法，在 ios 13 以上無效
//            https://try2explore.com/questions/10105773
            let navigationBar = navigationController?.navigationBar
            navigationBar?.shadowImage = UIImage()
        }
        
        if #available(iOS 12.0, *) {
            navigationItem.titleView = titleLabel
        } else {
            titleLabel.removeFromSuperview()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance.backgroundColor = navigationBarBackgroundColor
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
                //移除置頂是白色。畫面向下滑動變黑的特性
        } else {
            navigationController?.navigationBar.barTintColor = navigationBarBackgroundColor
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        previouseNavigationTitle = titleLabel.text ?? ""
        navigationItem.title = ""
    }
    
    public func didBecomeActive() {
        /// 給繼承類 override 用
    }

    var secondSettingValue: [Int] {
        [0, 3, 5, 7, 10, 15, 30, 60, 60*2, 60*3, 60*4, 60*5, 60*10, 60*15, 60*30, 60*60]
    }
    
    var opsSecondSettingValue: [Int] {
        [65535, 0, 1, 2, 3, 4, 5, 7, 10, 15, 30, 60, 60*2, 60*3, 60*4, 60*5, 60*10, 60*15, 60*30, 60*60]
    }
    
    // MARK: formatedTimeFromSec
    func formatedTimeFromSec(_ sec: Int) -> String {
        if sec > 0 && sec < 60 {
            return "\(sec) \("co.candyhouse.sesame2.sec".localized)"
        } else if sec >= 60 && sec < 60*60 {
            return "\(sec/60) \("co.candyhouse.sesame2.min".localized)"
        } else if sec == 65535 {
            return "\("co.candyhouse.sesame2.immediately".localized)"
        } else if sec >= 60*60 {
            return "\(sec/(60*60)) \("co.candyhouse.sesame2.hour".localized)"
        }  else {
            return "co.candyhouse.sesame2.off".localized
        }
    }
    
    func refreshCloudVersionTag(
        device: CHDevice,
        setVersionStr: @escaping (String) -> Void,
        setExclamationHidden: @escaping (Bool) -> Void
    ) {
        device.getVersionTag { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case .success(let status):
                let bleVersion = status.data
                let latestFwVer = device.stateInfo?.latestFwVer
                
                let isNewest: Bool = {
                    guard let latestFwVer = latestFwVer,
                          !latestFwVer.isEmpty else {
                        return false
                    }
                    
                    let tailTag = bleVersion
                        .split(separator: "-")
                        .last
                        .map(String.init) ?? ""
                    
                    return !tailTag.isEmpty && latestFwVer.contains(tailTag)
                }()
                
                let versionText = "\(bleVersion)\(isNewest ? "\("co.candyhouse.sesame2.latest".localized)" : "")"
                
                executeOnMainThread {
                    setVersionStr(versionText)
                    setExclamationHidden(latestFwVer == nil || isNewest)
                }
                
                if isNewest {
                    CHDeviceWrapperManager.shared.updateCurrentFwVer(
                        for: device.deviceId.uuidString,
                        currentFwVer: bleVersion
                    ) {
                        NotificationCenter.default.post(
                            name: .firmwareVersionUpdated,
                            object: nil,
                            userInfo: [
                                "deviceId": device.deviceId.uuidString
                            ]
                        )
                    }
                }
                
            case .failure(let error):
                L.d("[refreshCloudVersionTag]", error.errorDescription())
            }
        }
    }
    
    func presentCloudDfuConfirm(
        device: CHDevice,
        dfuView: CHUIPlainSettingView,
        delegate: DFUHelperDelegate
    ) {
        if isDfuActionLocked {
            view.makeToast("co.candyhouse.sesame2.dfu_busy".localized)
            return
        }
        
        let alert = UIAlertController(
            title: "",
            message: "co.candyhouse.sesame2.SesameOSUpdate".localized,
            preferredStyle: .actionSheet
        )
        
        let confirmAction = UIAlertAction(
            title: "co.candyhouse.sesame2.OK".localized,
            style: .default
        ) { [weak self] _ in
            self?.startCloudDfu(
                device: device,
                dfuView: dfuView,
                delegate: delegate
            )
        }
        
        alert.addAction(confirmAction)
        
        alert.addAction(UIAlertAction(
            title: "co.candyhouse.sesame2.Cancel".localized,
            style: .cancel,
            handler: nil
        ))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = dfuView
            popover.sourceRect = dfuView.bounds
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    func startCloudDfu(
        device: CHDevice,
        dfuView: CHUIPlainSettingView,
        delegate: DFUHelperDelegate
    ) {
        guard !isDfuActionLocked else {
            view.makeToast("co.candyhouse.sesame2.dfu_busy".localized)
            return
        }
        
        isDfuActionLocked = true
        shouldRefreshVersionAfterDfu = false
        
        dfuView.value = "co.candyhouse.sesame2.Downloading".localized
        
        DFUCenter.shared.dfuDevice(device, delegate: delegate)
    }
    
    func handleCloudDfuState(
        _ state: DFUState,
        dfuView: CHUIPlainSettingView
    ) {
        executeOnMainThread { [weak self] in
            guard let self = self else { return }
            
            switch state {
            case .starting:
                dfuView.value = "co.candyhouse.sesame2.StartingSoon".localized
                
            case .completed:
                self.isDfuActionLocked = false
                self.shouldRefreshVersionAfterDfu = true
                dfuView.value = "co.candyhouse.sesame2.Succeeded".localized
                
            case .aborted:
                self.isDfuActionLocked = false
                
            default:
                break
            }
        }
    }
    
    func handleCloudDfuError(
        message: String
    ) {
        executeOnMainThread { [weak self] in
            guard let self = self else { return }

            self.isDfuActionLocked = false
            self.view.makeToast(message)
        }
    }
    
    func handleCloudDfuProgress(
        dfuView: CHUIPlainSettingView,
        progress: Int
    ) {
        executeOnMainThread {
            dfuView.value = "\(progress)%"
        }
    }
    
    func consumeShouldRefreshVersionAfterDfu() -> Bool {
        if shouldRefreshVersionAfterDfu {
            shouldRefreshVersionAfterDfu = false
            return true
        }
        
        return false
    }

}
