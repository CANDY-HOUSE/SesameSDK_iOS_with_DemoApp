//
//  PasscodeVC.swift
//  SesameUI
//
//  Created by tse on 2023/5/23.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

struct KeyboardPassCode {
    var id: String
    var name: String
    var nameUUID: String
    
    mutating func setPassCodeName(changeName: String) {
        self.name = changeName
    }
}

extension KeyboardPassCode {
    func toBiometricData() -> BiometricData {
        return BiometricData(credentialId: id, nameUUID: nameUUID, type: String(0), name: "")
    }
    
    static var opType: String {
        return "passcode"
    }
    
    static func toBiometricDataWarpper(_ deviceUUID: String, _ passCode: KeyboardPassCode) -> BiometricDataWrapper {
        return BiometricDataWrapper(op: opType, deviceID: deviceUUID, items: [passCode.toBiometricData()])
    }
    
    static func toBiometricListDataWarpper(_ deviceUUID: String, _ passCodeList: [KeyboardPassCode]) -> BiometricDataWrapper {
        let biometricList = passCodeList.map { $0.toBiometricData() }
        return BiometricDataWrapper(op: opType, deviceID: deviceUUID, items: biometricList)
    }
    
}

extension BiometricData {
    func toPassCode() -> KeyboardPassCode {
        return KeyboardPassCode(id: credentialId, name: name, nameUUID: nameUUID)
    }
    static func toPassCodeList(items: [BiometricData]) -> [KeyboardPassCode] {
        return items.map { $0.toPassCode() }
    }
}

extension PassCodeVC {
    static func instance(_ device: CHPassCodeCapable) -> PassCodeVC {
        let vc = PassCodeVC(nibName: nil, bundle: nil)
        vc.mDevice = device
        return vc
    }
}

class PassCodeVC: CHBaseTableVC ,CHPassCodeDelegate, CHDeviceStatusDelegate{

    var mDevice: CHPassCodeCapable!
    var mPassCodeList = [KeyboardPassCode]()
    var refreshControl: UIRefreshControl = UIRefreshControl()
    let dismissButton = UIButton(type: .custom)
    var isRegistrerMode = false {
        didSet {
            executeOnMainThread { [self] in
                L.d("isRegistrerMode!!!",isRegistrerMode)
                if(self.isRegistrerMode){
                    self.dismissButton.setImage(UIImage.SVGImage(named: "icons_filled_close"), for: .normal)
                }else{
                    self.dismissButton.setImage(UIImage.SVGImage(named: "icons_outlined_addoutline"), for: .normal)
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        L.d("[NFC][viewDidLoad]")

        navigationBarBackgroundColor = .white
        tableView.register(UINib(nibName: "FingerPrintCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.refreshControl = refreshControl
        tableView.bounces = false

        let dismissButtonItem = UIBarButtonItem(customView: dismissButton)
        dismissButtonItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        dismissButtonItem.customView?.heightAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButtonItem.customView?.widthAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButton.addTarget(self, action: #selector(rightMenuClick), for: .touchUpInside)
        navigationItem.rightBarButtonItem = dismissButtonItem
        title = "0/100"
        mDevice.delegate = self
        if let capable = mDevice as? CHPassCodeCapable {
            capable.registerEventDelegate(self)
        }
        mDevice.passCodeModeGet(){ result in
            if case let .success(isEnabled) = result {
                self.isRegistrerMode = (isEnabled.data == 0x01)
                L.d("[NFC][isRegistrerMode:\(self.isRegistrerMode)]:")
            }
        }
        mDevice.passCodes(){ _ in}
        let deviceName = mDevice.getDeviceName()
        let emptyHit = String(format:"co.candyhouse.sesame2.TouchEmptyPasscodeHint".localized,
                                 arguments:[deviceName])
        let floatView = FloatingTipView.showIn(superView: view, style:  .textOnly(text:emptyHit))
        executeOnMainThread { [weak self] in
            self?.tableView.contentInset = .init(top: floatView.FloatingHeight, left: 0, bottom: 0, right: 0)
        }
    }

    @objc func rightMenuClick() {
        mDevice.passCodeModeSet(mode: isRegistrerMode ? 0x00:0x01){ [self]_ in
            isRegistrerMode = !isRegistrerMode
        }
    }


    override func viewWillDisappear(_ animated: Bool) {
        mDevice.passCodeModeSet(mode: 0x00){_ in  }
        if let capable = mDevice as? CHPassCodeCapable {
            capable.unregisterEventDelegate(self)
        }
    }

    override func reloadTableView() {
        super.reloadTableView()
        executeOnMainThread {
            self.title = "\(self.mPassCodeList.count)/100"
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        mPassCodeList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FingerPrintCell
        let card = mPassCodeList[indexPath.row]
        let titleText = card.id.hexStringToIntStr()
        let nameText = card.name.isEmpty ? "co.candyhouse.sesame2.default_passcode_name".localized : card.name
        cell.mImage.image = UIImage(named: "keyboard")
        cell.keyName.text = nameText
        cell.keyID.text = titleText
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var passCode = mPassCodeList[indexPath.row]
        let titleText = passCode.id.hexStringToIntStr()
        let nameText = passCode.name.isEmpty ? "co.candyhouse.sesame2.default_passcode_name".localized : passCode.name
        let alertController = UIAlertController(title: "", message: titleText, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.TouchProPWDModify".localized, style: .default) { _ in
            let renameToServer: (_ name: String, _ nameUUID: String) -> Void = { name, uuid in
                CHUserAPIManager.shared.getSubId { subId in
                    let subUUID = subId ?? ""
                    let request = CHKeyBoardPassCodeNameRequest(type: 0,
                                                                keyBoardPassCodeNameUUID: uuid,
                                                                subUUID: subUUID,
                                                                stpDeviceUUID: self.mDevice.deviceId.uuidString.uppercased(),
                                                                name: name,
                                                                keyBoardPassCode: passCode.id)
                    self.mDevice.passCodeNameSet(passCodeNameRequest: request,){ result in
                        if case let .failure(error) = result {
                            executeOnMainThread {
                                self.view.makeToast(error.errorDescription())
                            }
                            return
                        }
                        if case .success(_) = result {
                            passCode.setPassCodeName(changeName: name)
                            executeOnMainThread {
                                self.mPassCodeList[indexPath.row] = passCode
                                self.reloadTableView()
                            }
                        }
                    }
                }
            }
            ChangeValueDialog.show(nameText, title: "co.candyhouse.sesame2.EditName".localized) { name in
                if BiometricData.isUUIDv4(name: passCode.nameUUID) {
                  renameToServer(name, passCode.nameUUID)
                } else {
                    let uuid = UUID().uuidString.lowercased()
                    self.mDevice.passCodeChange(ID: passCode.id, name: uuid.replacingOccurrences(of: "-", with: "")){ _ in
                        self.mPassCodeList.removeAll { value in
                            return value.id == passCode.id
                        }
                        self.reloadTableView()
                        renameToServer(name, uuid)
                    }
                }
            }
        })
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.Delete".localized, style: .destructive ) { _ in
            executeOnMainThread { [self] in
                mDevice.passCodeDelete(ID: passCode.id){ _ in }
            }
        })
        let cancel = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil)
        alertController.addAction(cancel)
        alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
        present(alertController, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 100 }

    func onPassCodeReceiveStart(device: CHSesameConnector) {
        executeOnMainThread {
            self.mPassCodeList.removeAll()
            self.refreshControl.programaticallyBeginRefreshing(in:self.tableView)
        }
    }
    func onPassCodeReceive(device: CHSesameConnector, id: String, name: String, type: UInt8) {
        executeOnMainThread {
            if BiometricData.isUUIDv4(name: name) {
                self.mPassCodeList.insert(KeyboardPassCode(id: id, name: "", nameUUID: name.noDashtoUUID()!.uuidString.lowercased()), at: 0)
            } else {
                self.mPassCodeList.insert(KeyboardPassCode(id: id, name: name, nameUUID: name), at: 0)
            }
            self.reloadTableView()
        }
    }
    func onPassCodeReceiveEnd(device: CHSesameConnector) {
        executeOnMainThread {
            self.refreshControl.programaticallyEndRefreshing(in:self.tableView)
            self.reloadTableView()
            guard let capable = device as? CHPassCodeCapable else {
                return
            }
            capable.postAuthenticationData(KeyboardPassCode.toBiometricListDataWarpper(self.mDevice.deviceId.uuidString, self.mPassCodeList)) { response in
                if case let .success(data) = response {
                    self.mPassCodeList = BiometricData.toPassCodeList(items: data.data)
                    executeOnMainThread {
                        self.reloadTableView()
                    }
                } else if case let .failure(error) = response {
                    executeOnMainThread {
                        self.view.makeToast(error.errorDescription())
                    }
                }
            }
        }
    }

    func onPassCodeChanged(device: CHSesameConnector, id: String, name: String, type: UInt8) {
        executeOnMainThread {
            var keyboardPassCode = KeyboardPassCode(id: id, name: name, nameUUID: name)
            if BiometricData.isUUIDv4(name: name) {
                keyboardPassCode = KeyboardPassCode(id: id, name: "", nameUUID: name.noDashtoUUID()!.uuidString.lowercased())
            }
            self.mPassCodeList.insert(keyboardPassCode, at: 0)
            self.reloadTableView()
            guard let capable = device as? CHPassCodeCapable else {
                return
            }
            capable.putAuthenticationData(KeyboardPassCode.toBiometricDataWarpper(self.mDevice.deviceId.uuidString, keyboardPassCode)) { response in
                if case let .failure(error) = response {
                    executeOnMainThread {
                        self.view.makeToast(error.errorDescription())
                    }
                }
            }
        }
    }
    
    func onPassCodeModeChanged(mode: UInt8) {
        executeOnMainThread {
            self.isRegistrerMode = (mode == 0x01)
        }
    }
    
    func onPassCodeDelete(device: CHSesameConnector, id: String) {
        executeOnMainThread {
            if let index = self.mPassCodeList.firstIndex(where: { $0.id.lowercased() == id.lowercased() }) {
                let removedPassCode = self.mPassCodeList.remove(at: index)
                self.deletePassCodeFromServer(removedPassCode)
                self.reloadTableView()
            }
        }
    }
    
    func deletePassCodeFromServer(_ passCode: KeyboardPassCode) {
        guard let capable = mDevice as? CHPassCodeCapable else {
            return
        }
        capable.deleteAuthenticationData(KeyboardPassCode.toBiometricDataWarpper(self.mDevice.deviceId.uuidString, passCode)) { response in
            if case let .failure(error) = response {
                executeOnMainThread {
                    self.view.makeToast(error.errorDescription())
                }
            }
        }
    }

}
