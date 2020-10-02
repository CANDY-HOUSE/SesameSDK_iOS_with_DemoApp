//
//  SSM2SettingViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import AWSMobileClient

public final class SSMSettingViewModel: ViewModel {
    private let id = UUID()
    // Data
    private var memberList = [SSMOperator]()
    private var ssm: CHSesameBleInterface
    // Display
    private var delay = 0
    private var version = ""
    // Status
    private var isHiddenAutoLockDisplay = true
    private var switchIsOn = true {
        didSet {
            if switchIsOn == false {
                isHiddenAutoLockDisplay = true
            }
        }
    }
    private var isHiddenPicker = true
    
    public var statusUpdated: ViewStatusHandler?
    
    private var dfuHelper: DFUHelper?
    
    var delegate: SSM2SettingViewModelDelegate?
    
    // MARK: - Properties
    private(set) var changeNameIndicator = "Change Sesame Name".localStr
    private(set) var enterSesameName = "Enter Sesame name".localStr
    private(set) var angleIndicator = "Configure Angles".localStr
    private(set) var dfuIndicator = "SesameOS Update".localStr
    private(set) var removeSesameIndicator = "Delete this Sesame".localStr
    private(set) var autoLockLabel1Text = "autolock".localStr
    private(set) var autoLockLabel2Text = "After".localStr
    private(set) var autoLockLabel3Text = "sec".localStr
    private(set) var arrowImg = "arrow"
    
    var title: String {
        ssm.deviceId!.uuidString
    }
    
    var autolockSwitchIsEnabled: Bool {
        ssm.deviceStatus.loginStatus() == .login
    }
    
    var isAutoLockSwitchOn: Bool {
        switchIsOn
    }
    
    var autoLockDisplay: String {
        String(delay)
    }
    
    var isAutoLockSecondHidden: Bool {
        isHiddenAutoLockDisplay
    }
    
    var isAutoLockLabel1Hidden: Bool {
        false
    }
    
    var isAutoLockLabel2Hidden: Bool {
        isHiddenAutoLockDisplay
    }
    
    var isAutoLockLabel3Hidden: Bool {
        isHiddenAutoLockDisplay
    }
    
    var secondPickerIsHidden: Bool {
        isHiddenPicker
    }
    
    var ssmVersionText: String {
        version
    }

    var autoLockSecondText: String {
        String(delay)
    }
    
    init(ssm: CHSesameBleInterface) {
        self.ssm = ssm
        self.ssm.updateObserver(self, forKey: id.uuidString)
        CHBLEDelegatesManager.shared.updateObserver(self, forKey: id.uuidString)
    }

    // MARK: - User interaction
    public func viewDidLoad() {
        
    }
    
    public func viewWillAppear() {
        getDeviceMembers()
        getAutoLockSetting()
        getVersionTag()
        isHiddenPicker = true
    }
    
    public func viewDidAppear() {
        
    }
    
    public func viewWillDisappear() {
        
    }
    
    public func viewDidDisappear() {
        dfuHelper?.abort()
        dfuHelper = nil
    }
    
    @objc func autoLockSwitchChanged(sender: UISwitch) {
        if !sender.isOn {
            ssm.disableAutolock() { [weak self] (delay) -> Void in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.statusUpdated?(.received)
            }
            isHiddenPicker = true
        } else {
            isHiddenPicker = false
        }
        switchIsOn = sender.isOn
        statusUpdated?(.received)
    }
    
    // MARK: - Business logic
    private func getDeviceMembers() {
//        ssm.getDeviceMembers() { [weak self] result in
//            guard let strongSelf = self else {
//                return
//            }
//            switch result {
//            case .success(let users):
//                strongSelf.memberList = users.data.sorted(by: {$0.roleType! > $1.roleType!})
//                strongSelf.statusUpdated?(.received)
//                
//            case .failure(let error):
//                L.d(ErrorMessage.descriptionFromError(error: error))
//                strongSelf.statusUpdated?(.finished(.failure(error)))
//            }
//            strongSelf.statusUpdated?(.received)
//        }
    }
    
    private func getAutoLockSetting() {
        ssm.toggleWithHaptic(interval: 1.5)
    }
    
    private func getVersionTag() {
        ssm.getVersionTag { [weak self] (version, _) -> Void in
            guard let strongSelf = self else {
                return
            }
            strongSelf.version = version
            strongSelf.statusUpdated?(.received)
        }
    }
    
    deinit {
        ssm.removeObserver(forKey: id.uuidString)
        CHBLEDelegatesManager.shared.removeObserver(forKey: id.uuidString)
    }
}

// MARK: - Delegate
extension SSMSettingViewModel: CHSesameBleDeviceDelegate, CHBleManagerDelegate {
    public func onBleDeviceStatusChanged(device: CHSesameBleInterface,
                                         status: CHDeviceStatus) {
        ssm = device
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { // Change `2.0` to the desired
            _ = self.ssm.getVersionTag { (version, _) -> Void in
                self.version = version
                self.statusUpdated?(.received)
            }
        }
    }
    
    public func onBleCommandResult(device: CHSesameBleInterface,
                                   command: SSM2ItemCode,
                                   returnCode: SSM2CmdResultCode) {
        if command == .history {
            //            viewModel.getHistory()
            statusUpdated?(.received)
        }
        
    }
    
    public func didDiscoverSesame(device: CHSesameBleInterface) {
        if device.deviceId == self.ssm.deviceId {
            self.ssm = device
            device.updateObserver(self, forKey: id.uuidString)
            ssm.connect()
        }
    }
}

// MARK: - AutoLock
extension SSMSettingViewModel {
    var second: [Int] {
        [1,2,3,4,5,6,7,8,9,10,11,12,13]
    }

    func numberOfComponents() -> Int {
        1
    }
    
    func numberOfRowInComponent() -> Int {
        return second.count
    }
    
    func pickerTextForRow(_ row: Int) -> String {
        String(second[row])
    }
    
    func autolockSecondTapped() {
        defer {
            statusUpdated?(.received)
        }
        if delay == 0 {
            isHiddenPicker = true
            switchIsOn = false
            return
        } else {
            switchIsOn = true
            isHiddenAutoLockDisplay = false
        }
        isHiddenPicker.toggle()
    }
    
    func pickerDidSelectRow(_ row: Int) {
//        L.d(String(row)+"-"+String(component))
        ssm.enableAutolock(delay: second[row]) { [weak self] (delay) -> Void in
            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async {
                strongSelf.delay = delay
                strongSelf.isHiddenAutoLockDisplay = delay > 0 ? false : true
                strongSelf.isHiddenPicker = true
                strongSelf.statusUpdated?(.received)
            }
        }
    }
}

// MARK: - DFU
extension SSMSettingViewModel {
    public func dfuActionText() -> String {
        "SesameOS Update".localStr
    }
    
    public func dfuActionWithObserver(_ observer: DFUHelperObserver) {
        guard let filePath = Constant
            .resourceBundle
            .url(forResource: nil,
                 withExtension: ".zip"),
            let zipData = try? Data(contentsOf: filePath) else {
                return
        }
        
        ssm.updateFirmware { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let peripheral):
                guard let peripheral = peripheral.data else {
                    L.d("Request commad failed.")
                    return
                }
                L.d("Success.")
                strongSelf.dfuHelper = CHDFUHelper(peripheral: peripheral, zipData: zipData)
                strongSelf.dfuHelper?.observer = observer
                strongSelf.dfuHelper?.start()
            case .failure(let error):
                L.d(ErrorMessage.descriptionFromError(error: error))
                strongSelf.statusUpdated?(.finished(.failure(error)))
            }
            
        }
    }
    
    public func cancelDFU() {
        dfuHelper?.abort()
        dfuHelper = nil
    }
}

// MARK: - Rename
extension SSMSettingViewModel {
    func renameTitle() -> String {
        ssm.deviceId!.uuidString
        
    }
    
    func rename(_ name: String) {
//        ssm.renameDevice(name:name) { [weak self] result in
//            guard let strongSelf = self else {
//                return
//            }
//            switch result {
//            case .success(_):
////                    (self.tabBarController as? GeneralTabViewController)?.delegateHome?.refreshKeychain()
////                    (self.tabBarController as? GeneralTabViewController)?.delegateHome?.refleshRoomBackTitle(name: name)
//                strongSelf.statusUpdated?(.received)
//            case .failure(let error):
//                strongSelf.statusUpdated?(.finished(.failure(error)))
//            }
//        }
    }
}

// MARK: - Friends
extension SSMSettingViewModel {
    func numberOfItemsInSection(_ section: Int) -> Int {
        memberList.count + 2
    }
    
    func userCellViewModelForItemAt(_ indexPath: IndexPath) -> UserCellViewModel {
        if indexPath.row == self.memberList.count {
            return UserCellViewModel(avatar: "icon_add", isOwnerKingHidden: true)
        } else if indexPath.row == (self.memberList.count + 1) {
            return UserCellViewModel(avatar: "icon_delete", isOwnerKingHidden: true)
        } else {
            let client = self.memberList[indexPath.row]
            if client.roleType == CHDeviceAccessLevel.owner.rawValue {
                return UserCellViewModel(avatar: "owner_king", isOwnerKingHidden: false)
            } else {
                return UserCellViewModel(avatar: "owner_king", isOwnerKingHidden: true)
            }
        }
    }
    
    func transformOwnerShipAlertTitleByIndexPath(_ indexPath: IndexPath) -> String? {
        let client = self.memberList[indexPath.row]
        return client.name
    }
    
    func transformOwnerShipActionTitle() -> String {
        "Transfer ownership to this member".localStr
    }
    
    func trnasformOwnerShipToUser(_ client: SSMOperator) {
        statusUpdated?(.loading)
        
//        ssm.transferOwner(client.id) { [weak self] result in
//            guard let strongSelf = self else {
//                return
//            }
//
//            switch result {
//            case .success(_):
//                strongSelf.ssm.getDeviceMembers() { result in
//                    switch result {
//                    case .success(let users):
//                        strongSelf.memberList = users.data.sorted(by: {$0.roleType! > $1.roleType!})
//                        strongSelf.statusUpdated?(.received)
//                    case .failure(let error):
//                        L.d(ErrorMessage.descriptionFromError(error: error))
//                        strongSelf.statusUpdated?(.finished(.failure(error)))
//                    }
//                }
//            case .failure(let error):
//                L.d(ErrorMessage.descriptionFromError(error: error))
//                strongSelf.statusUpdated?(.finished(.failure(error)))
//            }
//        }
    }
    
    func collectionViewDidSelectItemAtIndexPath(_ indexPath: IndexPath) -> (()->Void)? {
        if indexPath.row == memberList.count {
            delegate?.addFriends(currentFriends: memberList)
            return nil
        } else if indexPath.row == memberList.count + 1 {
            delegate?.removeFriends(currentFriends: memberList)
            return nil
        } else {
            let client = memberList[indexPath.row]
            if client.roleType != CHDeviceAccessLevel.owner.rawValue {
                let action = {
//                    self.ssm.transferOwner(client.id) { [weak self] result in
//                        guard let strongSelf = self else {
//                            return
//                        }
//                        switch result {
//                        case .success(_):
//                            strongSelf.ssm.getDeviceMembers() { result in
//                                switch result {
//                                case .success(let users):
//                                    DispatchQueue.main.async {
//                                        strongSelf.memberList = users.data.sorted(by: {$0.roleType! > $1.roleType!})
//                                        strongSelf.statusUpdated?(.received)
//                                    }
//                                case .failure(let error):
//                                    L.d(ErrorMessage.descriptionFromError(error: error))
//                                    strongSelf.statusUpdated?(.finished(.failure(error)))
//                                }
//                            }
//                        case .failure(let error):
//                            L.d(ErrorMessage.descriptionFromError(error: error))
//                            strongSelf.statusUpdated?(.finished(.failure(error)))
//                        }
//                    }
                }
                return action
            }
            return nil
        }
    }
    
    public func deleteSesameTitle() -> String {
        "Delete this Sesame".localStr
    }
    
    public func deleteSeesameAction() {
        statusUpdated?(.loading)
        
        guard AWSMobileClient.default().isSignedIn == true else {
            // Delete local key
            ssm.unregister()
            CHAccountManager.shared.deleteCHDeviceByBleID(ssm.deviceId!)
            NotificationCenter.default.post(name: .SesameDeleted, object: nil)
            delegate?.sesameDeleted()
//            self.navigationController?.popToRootViewController(animated: true)
//            if let tb = self.tabBarController as? GeneralTabViewController {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
//                    tb.delegateHome?.refreshKeychain()
//                }
//            }
            statusUpdated?(.finished(.success("")))
            return
        }
        
//        ViewHelper.showLoadingInView(view: self.view)
        
        ssm.unregisterServer() { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(_):
                _ = strongSelf.ssm.unregister()
                strongSelf.delegate?.sesameDeleted()
                strongSelf.statusUpdated?(.finished(.success("")))
//                DispatchQueue.main.async {
//                    let tb =  self.tabBarController as! GeneralTabViewController
//                    self.navigationController?.popToRootViewController(animated: true)
//
//                    //todo kill this delay
//                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.2) {
//                        tb.delegateHome?.refreshKeychain()
//                    }
//                }
            case .failure(let error):
//                L.d(ErrorMessage.descriptionFromError(error: error))
//                DispatchQueue.main.async {
//                    self.view.makeToast(ErrorMessage.descriptionFromError(error: error))
//                }
                strongSelf.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
}

public protocol SSM2SettingViewModelDelegate {
    func setAngleForSSM(_ ssm: CHSesameBleInterface)
    func shareSSMTapped(_ ssm: CHSesameBleInterface)
    func sesameDeleted()
    func addFriends(currentFriends: [SSMOperator])
    func removeFriends(currentFriends: [SSMOperator])
}

// MARK: - Navigation
extension SSMSettingViewModel {
    func setAngleTapped() {
        delegate?.setAngleForSSM(ssm)
    }
    
    func shareSSMTapped() {
        delegate?.shareSSMTapped(ssm)
    }
}
