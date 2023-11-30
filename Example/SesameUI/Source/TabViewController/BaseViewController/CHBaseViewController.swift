//
//  CHBaseVC.swift
//  [navigation views]
//  Created by tse on 2020/3/28.
//  Copyright © 2020 CandyHouse. All rights reserved.
//
import UIKit
import AVFoundation
import SesameSDK
import CoreBluetooth
import Foundation

public class CHBaseViewController: UIViewController, PopUpMenuDelegate {
   
    @objc  func handleRightBarButtonTapped(_ sender: Any) {
        if self.popUpMenuControl == nil { return }
        if self.popUpMenuControl.superview != nil {
            popUpMenuControl.hide(animated: true)
        } else {
            popUpMenuControl.show(in: UIApplication.shared.keyWindow!)
        }
    }

    func popUpMenu(_ menu: PopUpMenu, didTap item: PopUpMenuItem) {
        if(item.type == .addSesame2){
            presentRegisterSesame2ViewController()
        } else { return }
        popUpMenuControl.hide(animated:false)
    }
    
    // MARK: - UI components
    lazy var popUpMenuControl: PopUpMenuControl = {
        let y = UIApplication.shared.statusBarFrame.height + 25
        let frame = CGRect(x: 0, y: y, width: view.bounds.width, height: view.bounds.height - y)
        let popUpMenuControl = PopUpMenuControl(frame: frame)
        popUpMenuControl.delegate = self
        return popUpMenuControl
    }()
    
    // MARK: - Properties
    private var previouseNavigationTitle = ""
    
    public override var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    var soundPlayer: AVAudioPlayer?
    var navigationBarBackgroundColor: UIColor = .sesame2Gray
    
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
    public override func viewDidLoad() {
        super.viewDidLoad()
        _ = BleHelper.shared // 初始化UI端的藍芽

        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance.shadowColor = .clear
        } else {
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
        [0, 3, 5, 7, 10, 15, 30, 60, 60*2, 60*5, 60*10, 60*15, 60*30, 60*60]
    }
    
    var opsSecondSettingValue: [Int] {
        [65535, 0, 3, 5, 7, 10, 15, 30, 60, 60*2, 60*5, 60*10, 60*15, 60*30, 60*60]
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

    func presentRegisterSesame2ViewController() {
        let registerSesame2ViewController = RegisterSesameDeviceViewController.instance { registeredDevice in
            executeOnMainThread {

            if let navController = GeneralTabViewController.switchTabByIndex(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
            if let device = registeredDevice as? CHSesame2 {
                    listViewController.navigateToSesame2LockAngleSetting(device)
            }
            if let device = registeredDevice as? CHSesame5 {
                    listViewController.navigateToSesame5LockAngleSetting(device)
            }
            if let device = registeredDevice as? CHWifiModule2 {
                    listViewController.navigateToWifiModule2SettingViewController(device, isFromRegister: true)
            }
            if let device = registeredDevice as? CHSesameTouchPro {
                if(device.productModel == .openSensor){
                    listViewController.navigateToOpenSensorSettingVC(device, isFromRegister: true)
                }else if(device.productModel == .bleConnector){
                    listViewController.navigateToBleConnectorVC(device, isFromRegister: true)
                }else{
                    listViewController.navigateToCHSesameTouchProSettingVC(device, isFromRegister: true)
                }
            }
                listViewController.getKeysFromCache()
                }
            }
        }
        present(registerSesame2ViewController.navigationController!, animated: true, completion: nil)
    }
    
    func navigateToSesame2History(_ sesame2: CHSesame2) {
        navigationController?.pushViewController(Sesame2HistoryViewController.instanceWithSesame2(sesame2) {/** self.getKeysFromCache()*/}, animated: true)
    }
    func navigateToSesame5History(_ sesame5: CHSesame5) {
        navigationController?.pushViewController(Sesame5HistoryViewController.instance(sesame5) { /** self.getKeysFromCache()*/}, animated: true)
    }
    func navigateToSesame5Setting(_ sesame5: CHSesame5) {
        navigationController?.pushViewController(Sesame5SettingViewController.instance(sesame5) { _ in /** self.getKeysFromCache()*/}, animated: true)
    }
    func navigateToSesame2Setting(_ sesame2: CHSesame2) {
        navigationController?.pushViewController(Sesame2SettingViewController.instanceWithSesame2(sesame2) { _ in /** self.getKeysFromCache()*/}, animated: true)
    }
    func navigateToSesame2LockAngleSetting(_ sesame2: CHSesame2) {
        self.navigationController?.pushViewController(LockAngleSettingViewController.instanceWithSesame2(sesame2) {/** self.getKeysFromCache()*/ }, animated: true)
    }
    func navigateToSesame5LockAngleSetting(_ sesame5: CHSesame5) {
        self.navigationController?.pushViewController(Sesame5LockAngleViewController.instance(sesame5) { /** self.getKeysFromCache()*/ }, animated: true)
    }

    func navigateToSesameBotSettingViewController(_ sesameBot: CHSesameBot) {
        navigationController?.pushViewController(SesameBotSettingViewController.instanceWithSwitch(sesameBot) {/** self.getKeysFromCache()*/ },animated: true)
    }

    func navigateToBikeLockSettingViewController(_ bikeLock: CHSesameBike) {
        navigationController?.pushViewController(BikeLockSettingViewController.instanceWithBikeLock(bikeLock) {},animated: true)
    }
    
    func navigateToBike2SettingViewController(_ bikeLock2: CHSesameBike2) {
        navigationController?.pushViewController(BikeLock2SettingViewController.instanceWithBikeLock2(bikeLock2) {_ in },animated: true)
    }

    func navigateToWifiModule2SettingViewController(_ wifiModule2: CHWifiModule2, isFromRegister: Bool = false) {
        navigationController?.pushViewController(WifiModule2SettingViewController.instanceWithWifiModule2(wifiModule2, isFromRegister: isFromRegister) {/** self.getKeysFromCache()*/  },animated: true)
    }

    func navigateToCHSesameTouchProSettingVC(_ device: CHSesameTouchPro, isFromRegister: Bool = false) {
        navigationController?.pushViewController(SesameTouchProSettingVC.instance(device) {},animated: true)
    }
    
    func navigateToOpenSensorSettingVC(_ device: CHSesameTouchPro, isFromRegister: Bool = false) {
        navigationController?.pushViewController(OpenSensorSettingVC.instance(device) {},animated: true)
    }
    
    func navigateToOpenSensorResetVC(_ device: CHSesameTouchPro, isFromRegister: Bool = false) {
        navigationController?.pushViewController(OpenSensorResetHintVC.instance(device) {},animated: true)
    }
    
    func navigateToBleConnectorVC(_ device: CHSesameTouchPro, isFromRegister: Bool = false) {
        navigationController?.pushViewController(BleConnectorSettingVC.instance(device) {},animated: true)
    }
}
