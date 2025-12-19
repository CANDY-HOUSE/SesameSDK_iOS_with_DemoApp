//
//  FingerPrintListVC.swift
//  SesameUI
//  [joi][todo] 改指紋名稱字數:162
//  Created by tse on 2023/5/17.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
struct Face {
    var id: String
    var name: String
    var nameUUID: String
    
    mutating func setFaceName(changeName: String) {
        self.name = changeName
    }
}

extension Face {
    func toBiometricData() -> BiometricData {
        return BiometricData(credentialId: id, nameUUID: nameUUID, type: String(0), name: "")
    }
    
    static var opType: String {
        return "face"
    }
    
    static func toBiometricDataWarpper(_ deviceUUID: String, _ passCode: Face) -> BiometricDataWrapper {
        return BiometricDataWrapper(op: opType, deviceID: deviceUUID, items: [passCode.toBiometricData()])
    }
    
    static func toBiometricListDataWarpper(_ deviceUUID: String, _ passCodeList: [Face]) -> BiometricDataWrapper {
        let biometricList = passCodeList.map { $0.toBiometricData() }
        return BiometricDataWrapper(op: opType, deviceID: deviceUUID, items: biometricList)
    }
    
}

extension BiometricData {
    func toFace() -> Face {
        return Face(id: credentialId, name: name, nameUUID: nameUUID)
    }
    static func toFaceList(items: [BiometricData]) -> [Face] {
        return items.map { $0.toFace() }
    }
}

extension FaceListVC {
    static func instance(_ device: CHFaceCapable) -> FaceListVC {
        let vc = FaceListVC(nibName: nil, bundle: nil)
        vc.mDevice = device
        return vc
    }
}

class FaceListVC: CHBaseTableVC ,CHFaceDelegate, CHDeviceStatusDelegate{

    var mDevice: CHFaceCapable!
    var faceList = [Face]()
    var refreshControl: UIRefreshControl = UIRefreshControl()
    let dismissButton = UIButton(type: .custom)
    var isRegistrerMode = false {
        didSet {
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
        if let faceCapable = mDevice as? CHFaceCapable {
            faceCapable.registerEventDelegate(self)
        }
        mDevice.faceModeGet(){ result in
            if case let .success(isEnabled) = result {
                self.isRegistrerMode = (isEnabled.data == 0x01)
                L.d("[FG][isRegistrerMode:\(self.isRegistrerMode)]:")
            }
        }
        mDevice.faces(){ _ in}
        let emptyHit = String(format:"co.candyhouse.sesame2.faceProFaceHint".localized,
                              arguments:[mDevice.deviceName])
        let imageName: String
        switch self.mDevice.productModel {
        case .sesameFace:
            imageName = "face_tips"
        case .sesameFace2:
            imageName = "face_tips"
        default:
            imageName = "facepro_tips"
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
        mDevice.faceModeSet(mode: isRegistrerMode ? 0x00:0x01){ [self]_ in
            isRegistrerMode = !isRegistrerMode
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        mDevice.faceModeSet(mode: 0x00){_ in
            L.d("viewWillDisappear ok")
        }
        if let faceCapable = mDevice as? CHFaceCapable {
            faceCapable.unregisterEventDelegate(self)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        faceList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FingerPrintCell
        let card = faceList[indexPath.row]

        let titleNumber = Int(Data(hex: card.id)[0])
        let titleText = String(format: "%03d", titleNumber)
        let nameText = card.name.isEmpty ? "co.candyhouse.sesame2.default_face_name".localized : card.name

        cell.keyName.text = nameText
        cell.keyID.text = titleText
        cell.mImage.image = UIImage(named: "camera_face")
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var face = faceList[indexPath.row]
        let titleNumber = Int(Data(hex: face.id)[0])
        let titleText = String(format: "%03d", titleNumber) //指紋編號
        let nameText = face.name.isEmpty ? "co.candyhouse.sesame2.default_face_name".localized : face.name

        let alertController = UIAlertController(title: "", message: titleText, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.faceProFaceModify".localized, style: .default) { _ in
            let renameToServer: (_ name: String, _ nameUUID: String) -> Void = { name, uuid in
                CHUserAPIManager.shared.getSubId { subId in
                    let subUUID = subId ?? ""
                    let request = CHAuthenticationNameRequest.face(type: 0,
                                                    faceNameUUID: uuid,
                                                    subUUID: subUUID,
                                                    stpDeviceUUID: self.mDevice.deviceId.uuidString.uppercased(),
                                                    name: name,
                                                    faceID: face.id)
                    self.mDevice.updateAuthenticationName(request) { result in
                        if case let .failure(error) = result {
                            executeOnMainThread {
                                self.view.makeToast(error.errorDescription())
                            }
                            return
                        }
                        if case .success(_) = result {
                            face.setFaceName(changeName: name)
                            executeOnMainThread {
                                self.faceList[indexPath.row] = face
                                self.reloadTableView()
                            }
                        }
                    }
                }
            }
            ChangeValueDialog.show(nameText, title: "co.candyhouse.sesame2.EditName".localized) { name in
                renameToServer(name, face.nameUUID)
            }
        })
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.faceProFaceDelete".localized, style: .destructive ) { _ in
            executeOnMainThread { [self] in
                mDevice.faceDelete(ID: face.id){_ in }
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

    func onFaceReceiveStart(device: CHSesameConnector) {
        executeOnMainThread {
            self.faceList.removeAll()
            self.refreshControl.programaticallyBeginRefreshing(in:self.tableView)
        }
    }
    func onFaceReceive(device: CHSesameConnector, id: String, name: String, type: UInt8) {
        executeOnMainThread {
            self.faceList.insert(Face(id: id, name: "", nameUUID: name.noDashtoUUID()!.uuidString.lowercased()), at: 0)
            self.reloadTableView()
        }

    }
    func onFaceReceiveEnd(device: CHSesameConnector) {
        executeOnMainThread {
            self.refreshControl.programaticallyEndRefreshing(in:self.tableView)
            self.reloadTableView()
            guard let capable = device as? CHFaceCapable else {
                return
            }
            capable.postAuthenticationData(Face.toBiometricListDataWarpper(self.mDevice.deviceId.uuidString, self.faceList)) { response in
                if case let .success(data) = response {
                    self.faceList = BiometricData.toFaceList(items: data.data)
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
    
    func onFaceChanged(device: CHSesameConnector, id: String, name: String, type: UInt8) {
        L.d("[FG][onFaceChanged] \(id):\(name)")
        let face = Face(id: id, name: "", nameUUID: name.noDashtoUUID()!.uuidString.lowercased())
        self.faceList.insert(face, at: 0)
        self.reloadTableView()
        guard let capable = device as? CHFaceCapable else {
            return
        }
        capable.putAuthenticationData(Face.toBiometricDataWarpper(self.mDevice.deviceId.uuidString, face)) { response in
            if case let .failure(error) = response {
                executeOnMainThread {
                    self.view.makeToast(error.errorDescription())
                }
            }
        }
    }
    
    func onFaceModeChanged(mode: UInt8) {
        executeOnMainThread {
            self.isRegistrerMode = (mode == 0x01)
        }
    }
    
    override func reloadTableView() {
        super.reloadTableView()
        executeOnMainThread {
            self.title = "\(self.faceList.count)/100"
        }
    }
    
    func onFaceDeleted(faceId: UInt8,isSuccess:Bool) {
        executeOnMainThread {
            if isSuccess {
                if let index = self.faceList.firstIndex(where: { Int($0.id, radix: 16) == Int(faceId) }) {
                    let removedFace = self.faceList.remove(at: index)
                    self.deleteFaceFormServer(removedFace)
                    self.reloadTableView()
                }
            } else {
                self.view.makeToast("co.candyhouse.sesame2.delete_fail".localized)
            }
        }
    }
    
    func deleteFaceFormServer(_ face: Face) {
        guard let capable = mDevice as? CHFaceCapable else {
            return
        }
        capable.deleteAuthenticationData(Face.toBiometricDataWarpper(self.mDevice.deviceId.uuidString, face)) { response in
            if case let .failure(error) = response {
                self.view.makeToast(error.errorDescription())
            }
        }
    }

}
