//
//  FingerPrintListVC.swift
//  SesameUI
//  [joi][todo] 改指紋名稱字數:162
//  Created by tse on 2023/5/17.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
struct Palm {
    var id: String
    var name: String
    var nameUUID: String
    
    mutating func setPalmName(changeName: String) {
        self.name = changeName
    }
}


extension Palm {
    func toBiometricData() -> BiometricData {
        return BiometricData(credentialId: id, nameUUID: nameUUID, type: String(0), name: "")
    }
    
    static var opType: String {
        return "palm"
    }
    
    static func toBiometricDataWarpper(_ deviceUUID: String, _ palm: Palm) -> BiometricDataWrapper {
        return BiometricDataWrapper(op: opType, deviceID: deviceUUID, items: [palm.toBiometricData()])
    }
    
    static func toBiometricListDataWarpper(_ deviceUUID: String, _ palmList: [Palm]) -> BiometricDataWrapper {
        let biometricList = palmList.map { $0.toBiometricData() }
        return BiometricDataWrapper(op: opType, deviceID: deviceUUID, items: biometricList)
    }
    
}

extension BiometricData {
    func toPalm() -> Palm {
        return Palm(id: credentialId, name: name, nameUUID: nameUUID)
    }
    static func toPalmList(items: [BiometricData]) -> [Palm] {
        return items.map { $0.toPalm() }
    }
}

extension PalmListVC {
    static func instance(_ device: CHPalmCapable) -> PalmListVC {
        let vc = PalmListVC(nibName: nil, bundle: nil)
        vc.mDevice = device
        return vc
    }
}

class PalmListVC: CHBaseTableVC ,CHPalmDelegate, CHDeviceStatusDelegate{

    var mDevice: CHPalmCapable!
    var palmList = [Palm]()
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
        L.d("[FG][PalmListVC viewDidLoad]")
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
        if let palmCapable = mDevice as? CHPalmCapable {
            palmCapable.registerEventDelegate(self)
        }
        mDevice.delegate = self
        mDevice.palmModeGet(){ result in
            if case let .success(isEnabled) = result {
                self.isRegistrerMode = (isEnabled.data == 0x01)
                L.d("[FG][isRegistrerMode:\(self.isRegistrerMode)]:")
            }
        }
        mDevice.palms(){ _ in}
        let emptyHit = String(format:"co.candyhouse.sesame2.faceProPalmHint".localized,
                              arguments:[mDevice.deviceName])
        let imageName: String
        switch self.mDevice.productModel {
        case .sesameFace:
            imageName = "palm_tips"
        default:
            imageName = "palmpro_tips"
        }
        let floatView = FloatingTipView.showIn(
            superView: view,
            style: .topImageWithText(
                imageName: imageName,
                text: emptyHit
            )
        )
        executeOnMainThread { [weak self] in
            self?.tableView.contentInset = .init(top: floatView.FloatingHeight, left: 0, bottom: 0, right: 0)
        }
    }

    @objc func rightMenuClick() {
        mDevice.palmModeSet(mode: isRegistrerMode ? 0x00:0x01){ [self]_ in
            isRegistrerMode = !isRegistrerMode
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        mDevice.palmModeSet(mode: 0x00){_ in
            L.d("viewWillDisappear ok")
        }
        if let palmCapable = mDevice as? CHPalmCapable {
            palmCapable.unregisterEventDelegate(self)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        palmList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FingerPrintCell
        let card = palmList[indexPath.row]
        let titleNumber = Int(Data(hex: card.id)[0])
        let titleText = String(format: "%03d", titleNumber)
        let nameText = card.name.isEmpty ? "co.candyhouse.sesame2.default_palm_name".localized : card.name

        cell.keyName.text = nameText
        cell.keyID.text = titleText
        
        cell.mImage.image = UIImage(named: "camera_palm")
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var palm = palmList[indexPath.row]
        let titleNumber = Int(Data(hex: palm.id)[0])
        let titleText = String(format: "%03d", titleNumber)
        
        let nameText = palm.name.isEmpty ? "co.candyhouse.sesame2.default_palm_name".localized : palm.name

        let alertController = UIAlertController(title: "", message: titleText, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.faceProPalmModify".localized, style: .default) { _ in
            let renameToServer: (_ name: String, _ nameUUID: String) -> Void = { name, uuid in
                CHUserAPIManager.shared.getSubId { subId in
                    let subUUID = subId ?? ""
                    let request = CHAuthenticationNameRequest.palm(type: 0,
                                                    palmNameUUID: uuid,
                                                    subUUID: subUUID,
                                                    stpDeviceUUID: self.mDevice.deviceId.uuidString.uppercased(),
                                                    name: name,
                                                    palmID: palm.id)
                    self.mDevice.updateAuthenticationName(request) { result in
                        if case let .failure(error) = result {
                            executeOnMainThread {
                                self.view.makeToast(error.errorDescription())
                            }
                            return
                        }
                        if case .success(_) = result {
                            palm.setPalmName(changeName: name)
                            executeOnMainThread {
                                self.palmList[indexPath.row] = palm
                                self.reloadTableView()
                            }
                        }
                    }
                }
            }
            ChangeValueDialog.show(nameText, title: "co.candyhouse.sesame2.EditName".localized) { name in
                renameToServer(name, palm.nameUUID)
            }
        })
        
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.faceProPalmDelete".localized, style: .destructive ) { _ in
            executeOnMainThread { [self] in
                mDevice.palmDelete(ID: palm.id){ _ in }
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

    func onPalmReceiveStart(device: CHSesameConnector) {
        executeOnMainThread {
            self.palmList.removeAll()
            self.refreshControl.programaticallyBeginRefreshing(in:self.tableView)
        }
    }
    func onPalmReceive(device: CHSesameConnector, id: String, name: String, type: UInt8) {
        executeOnMainThread {
            self.palmList.insert(Palm(id: id, name: "", nameUUID: name.noDashtoUUID()!.uuidString.lowercased()), at: 0)
            self.reloadTableView()
        }

    }
    func onPalmReceiveEnd(device: CHSesameConnector) {
        executeOnMainThread {
            self.refreshControl.programaticallyEndRefreshing(in:self.tableView)
            self.reloadTableView()
            guard let capable = device as? CHPalmCapable else {
                return
            }
            capable.postAuthenticationData(Palm.toBiometricListDataWarpper(self.mDevice.deviceId.uuidString, self.palmList)) { response in
                if case let .success(data) = response {
                    self.palmList = BiometricData.toPalmList(items: data.data)
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
    
    func onPalmChanged(device: CHSesameConnector, id: String, name: String, type: UInt8) {
        L.d("[FG][onPalmChanged] \(id):\(name)")
        executeOnMainThread {
            let palm = Palm(id: id, name: "", nameUUID: name.noDashtoUUID()!.uuidString.lowercased())
            self.palmList.insert(palm, at: 0)
            self.reloadTableView()
            guard let capable = device as? CHPalmCapable else {
                return
            }
            capable.putAuthenticationData(Palm.toBiometricDataWarpper(self.mDevice.deviceId.uuidString, palm)) { response in
                if case let .failure(error) = response {
                    executeOnMainThread {
                        self.view.makeToast(error.errorDescription())
                    }
                }
            }
        }
    }
    
    func onPalmModeChanged(mode: UInt8) {
        executeOnMainThread {
            self.isRegistrerMode = (mode == 0x01)
        }
    }
    
    override func reloadTableView() {
        super.reloadTableView()
        executeOnMainThread {
            self.title = "\(self.palmList.count)/100"
        }
    }
    
    
    func onPalmDeleted(palmId: UInt8, isSuccess: Bool) {
        executeOnMainThread {
            if isSuccess {
                if let index = self.palmList.firstIndex(where: { Int($0.id, radix: 16) == Int(palmId) }) {
                    let removedPalm = self.palmList.remove(at: index)
                    self.deletePalmFromServer(removedPalm)
                    self.reloadTableView()
                }
            } else {
                self.view.makeToast("co.candyhouse.sesame2.delete_fail".localized)
            }
        }
    }
    
    func deletePalmFromServer(_ palm: Palm) {
        guard let capable = mDevice as? CHPalmCapable else {
            return
        }
        capable.deleteAuthenticationData(Palm.toBiometricDataWarpper(self.mDevice.deviceId.uuidString, palm)) { response in
            if case let .failure(error) = response {
                executeOnMainThread {
                    self.view.makeToast(error.errorDescription())
                }
            }
        }
    }

}
