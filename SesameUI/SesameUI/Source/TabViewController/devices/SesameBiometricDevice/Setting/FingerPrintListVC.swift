//
//  FingerPrintListVC.swift
//  SesameUI
//  [joi][todo] 改指紋名稱字數:162
//  Created by tse on 2023/5/17.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

struct FingerPrint {
    var id: String
    var name: String
    var nameUUID: String
    
    mutating func setFingerprintName(changeName: String) {
        self.name = changeName
    }
}

extension FingerPrint {

    func toBiometricData() -> BiometricData {
        return BiometricData(credentialId: id, nameUUID: nameUUID, type: String(0), name: "")
    }
    
    static var opType: String {
        return "fingerprint"
    }
    
    static func toBiometricDataWarpper(_ deviceUUID: String, _ fingerprint: FingerPrint) -> BiometricDataWrapper {
        return BiometricDataWrapper(op: opType, deviceID: deviceUUID, items: [fingerprint.toBiometricData()])
    }
    
    static func toBiometricListDataWarpper(_ deviceUUID: String, _ fingerprintList: [FingerPrint]) -> BiometricDataWrapper {
        let biometricList = fingerprintList.map { $0.toBiometricData() }
        return BiometricDataWrapper(op: opType, deviceID: deviceUUID, items: biometricList)
    }
}

extension BiometricData {
    func toFingerprint() -> FingerPrint {
        return FingerPrint(id: credentialId, name: name, nameUUID: nameUUID)
    }
    static func toFingerPrintList(items: [BiometricData]) -> [FingerPrint] {
        return items.map { $0.toFingerprint() }
    }
}

extension FingerPrintListVC {
    static func instance(_ device: CHFingerPrintCapable) -> FingerPrintListVC {
        let vc = FingerPrintListVC(nibName: nil, bundle: nil)
        vc.mDevice = device
        return vc
    }
}

class FingerPrintListVC: CHBaseTableVC ,CHFingerPrintDelegate, CHDeviceStatusDelegate{

    var mDevice: CHFingerPrintCapable!
    var fingerPrints = [FingerPrint]()
    var refreshControl: UIRefreshControl = UIRefreshControl()
    let dismissButton = UIButton(type: .custom)
    var isRegistrerMode = false{
        didSet{
            executeOnMainThread {
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
        L.d("[FG][viewDidLoad]")
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
        if let capable = mDevice as? CHFingerPrintCapable {
            capable.registerEventDelegate(self)
        }
        
        mDevice.fingerPrintModeGet(){ result in
            if case let .success(isEnabled) = result {
                self.isRegistrerMode = (isEnabled.data == 0x01)
                L.d("[FG][isRegistrerMode:\(self.isRegistrerMode)]:")
            }
        }
        mDevice.fingerPrints(){ _ in}
        let deviceName = mDevice.getDeviceName()
        let emptyHit = String(format:"co.candyhouse.sesame2.TouchEmptyFingerHint".localized,
                              arguments:[deviceName,deviceName])
        let floatView = FloatingTipView.showIn(superView: view, style: .imageText(gifImagePathName: "finger_print", text: emptyHit))
        executeOnMainThread { [weak self] in
            self?.tableView.contentInset = .init(top: floatView.FloatingHeight, left: 0, bottom: 0, right: 0)
        }
    }

    @objc func rightMenuClick() {
        mDevice.fingerPrintModeSet(mode: isRegistrerMode ? 0x02:0x01){ [self]_ in
            isRegistrerMode = !isRegistrerMode
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        mDevice.fingerPrintModeSet(mode: 0x02){_ in
            L.d("viewWillDisappear ok")
        }
        if let capable = mDevice as? CHFingerPrintCapable {
            capable.unregisterEventDelegate(self)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fingerPrints.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FingerPrintCell
        let card = fingerPrints[indexPath.row]

        let titleNumber = Int(Data(hex: card.id)[0]) + 1
        let titleText = String(format: "%03d", titleNumber)
        let nameText = card.name.isEmpty ? "co.candyhouse.sesame2.default_fingerprint_name".localized : card.name

        cell.keyName.text = nameText
        cell.keyID.text = titleText
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var fingerprint = fingerPrints[indexPath.row]
        let titleNumber = Int(Data(hex: fingerprint.id)[0]) + 1///todo check 指紋編號
        let titleText = String(format: "%03d", titleNumber) //指紋編號
        
        let nameText = fingerprint.name.isEmpty ? "co.candyhouse.sesame2.default_fingerprint_name".localized : fingerprint.name

        let alertController = UIAlertController(title: "", message: titleText, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.TouchProFingerModify".localized, style: .default) { _ in
            
            let renameToServer: (_ name: String, _ nameUUID: String) -> Void = { name, uuid in
                   CHUserAPIManager.shared.getSubId { subId in
                       let subUUID = subId ?? ""
                       let request = CHFingerPrintNameRequest(
                           type: 0,
                           fingerPrintNameUUID: uuid,
                           subUUID: subUUID,
                           stpDeviceUUID: self.mDevice.deviceId.uuidString.uppercased(),
                           name: name,
                           fingerPrintID: fingerprint.id
                       )
                       
                       self.mDevice.fingerPrintNameSet(fingerPrintNameRequest: request) { result in
                           if case let .failure(error) = result {
                               executeOnMainThread {
                                   self.view.makeToast(error.errorDescription())
                               }
                               return
                           }
                           if case .success(_) = result {
                               fingerprint.setFingerprintName(changeName: name)
                               executeOnMainThread {
                                   self.fingerPrints[indexPath.row] = fingerprint
                                   self.reloadTableView()
                               }
                           }
                       }
                   }
               }
               ChangeValueDialog.show(nameText, title: "co.candyhouse.sesame2.EditName".localized) { name in
                   if BiometricData.isUUIDv4(name: fingerprint.nameUUID) {
                       renameToServer(name, fingerprint.nameUUID)
                   } else {
                       let uuid = UUID().uuidString.lowercased()
                       self.mDevice.fingerPrintsChange(ID: fingerprint.id, name: uuid.replacingOccurrences(of: "-", with: "")) { _ in
                           self.fingerPrints.removeAll { value in
                               return value.id == fingerprint.id
                           }
                           self.reloadTableView()
                           renameToServer(name, uuid)
                       }
                   }
               }
        })
        
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.TouchProFingerDelete".localized, style: .destructive ) { _ in
            executeOnMainThread { [self] in
                mDevice.fingerPrintDelete(ID: fingerprint.id){ _ in }
            }
        })
        let cancel = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil)
        alertController.addAction(cancel)
        alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
        present(alertController, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        100
    }

    func onFingerPrintReceiveStart(device: CHSesameConnector) {
        executeOnMainThread {
            self.fingerPrints.removeAll()
            self.refreshControl.programaticallyBeginRefreshing(in:self.tableView)
        }
    }
    func onFingerPrintReceive(device: CHSesameConnector, id: String, name: String, type: UInt8) {
        executeOnMainThread {
            if BiometricData.isUUIDv4(name: name) {
                self.fingerPrints.insert(FingerPrint(id: id, name: "", nameUUID: name.noDashtoUUID()!.uuidString.lowercased()), at: 0)
            } else {
                self.fingerPrints.insert(FingerPrint(id: id, name: name, nameUUID: name), at: 0)
            }
            self.reloadTableView()
        }

    }
    func onFingerPrintReceiveEnd(device: CHSesameConnector) {
        executeOnMainThread {
            self.refreshControl.programaticallyEndRefreshing(in:self.tableView)
            self.reloadTableView()
            guard let capable = device as? CHFingerPrintCapable else {
                return
            }
            capable.postAuthenticationData(FingerPrint.toBiometricListDataWarpper(self.mDevice.deviceId.uuidString, self.fingerPrints)) { response in
                if case let .success(data) = response {
                    self.fingerPrints = BiometricData.toFingerPrintList(items: data.data)
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
    
    func onFingerPrintChanged(device: CHSesameConnector, id: String, name: String, type: UInt8) {
        L.d("[FG][onFingerPrintChanged] \(id):\(name)")
        var fingerprint = FingerPrint(id: id, name: name, nameUUID: name)
        if BiometricData.isUUIDv4(name: name) {
            fingerprint = FingerPrint(id: id, name: "", nameUUID: name.noDashtoUUID()!.uuidString.lowercased())
        }
        self.fingerPrints.insert(fingerprint, at: 0)
        executeOnMainThread {
            self.reloadTableView()
            guard let capable = device as? CHFingerPrintCapable else {
                return
            }
            capable.putAuthenticationData(FingerPrint.toBiometricDataWarpper(self.mDevice.deviceId.uuidString, fingerprint)) { response in
                if case let .failure(error) = response {
                    executeOnMainThread {
                        self.view.makeToast(error.errorDescription())
                    }
                }
            }
        }
    }
    
    func onFingerModeChange(mode: UInt8) {
        executeOnMainThread {
            self.isRegistrerMode = (mode == 0x01)
        }
    }
    
    func onFingerPrintDelete(device: CHSesameConnector, id: String){
        executeOnMainThread {
            if let index = self.fingerPrints.firstIndex(where: { $0.id.lowercased() == id.lowercased() }) {
                let removedFingerprint = self.fingerPrints.remove(at: index)
                self.deleteFingerprintFromServer(removedFingerprint)
                self.reloadTableView()
            }
        }
    }
    
    override func reloadTableView() {
        super.reloadTableView()
        executeOnMainThread {
            self.title = "\(self.fingerPrints.count)/100"
        }
    }
    
    func deleteFingerprintFromServer(_ fingerprint: FingerPrint) {
        guard let capable = mDevice as? CHFingerPrintCapable else {
            return
        }
        capable.deleteAuthenticationData(FingerPrint.toBiometricDataWarpper(self.mDevice.deviceId.uuidString, fingerprint)) { response in
            if case let .failure(error) = response {
                executeOnMainThread {
                    self.view.makeToast(error.errorDescription())
                }
            }
        }
    }

}
