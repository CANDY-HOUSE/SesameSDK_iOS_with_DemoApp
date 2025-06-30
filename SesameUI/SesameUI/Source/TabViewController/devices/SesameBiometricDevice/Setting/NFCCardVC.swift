//
//  NFCCardVC.swift
//  SesameUI
//
//  Created by tse on 2023/5/22.
//  Copyright © 2023 CandyHouse. All rights reserved.
//


import UIKit
import SesameSDK
struct SuiCard {
    var id: String
    var name: String
    var type: UInt8
    var nameUUID: String

    func setCardType(level: Int) {
        UserDefaults.standard.set(level, forKey: self.id)
    }
    
    mutating func setCardName(changeName: String) {
        self.name = changeName
    }

    func getCardType(level: Int) -> Int {
        return UserDefaults.standard.integer(forKey: self.id)
    }
}

extension SuiCard {
    func toBiometricData() -> BiometricData {
        return BiometricData(credentialId: id, nameUUID: nameUUID, type: String(type), name: "")
    }
    
    static var opType: String {
        return "nfc_card"
    }
    
    static func toBiometricDataWarpper(_ deviceUUID: String, _ card: SuiCard) -> BiometricDataWrapper {
        return BiometricDataWrapper(op: opType, deviceID: deviceUUID, items: [card.toBiometricData()])
    }
    
    static func toBiometricListDataWarpper(_ deviceUUID: String, _ cardList: [SuiCard]) -> BiometricDataWrapper {
        let biometricList = cardList.map { $0.toBiometricData() }
        return BiometricDataWrapper(op: opType, deviceID: deviceUUID, items: biometricList)
    }
    
}

extension BiometricData {
    func toSuiCard() -> SuiCard {
        return SuiCard(id: credentialId, name: name, type: UInt8(type) ?? 0, nameUUID: nameUUID)
    }
    static func toSuiCardList(items: [BiometricData]) -> [SuiCard] {
        return items.map { $0.toSuiCard() }
    }
}

extension NFCCardVC {
    static func instance(_ device: CHCardCapable) -> NFCCardVC {
        let vc = NFCCardVC(nibName: nil, bundle: nil)
        vc.mDevice = device
        return vc
    }
}


class NFCCardVC: CHBaseTableVC ,CHCardDelegate, CHDeviceStatusDelegate{

    var mDevice: CHCardCapable!
    var mCardList = [SuiCard]()
    var refreshControl: UIRefreshControl = UIRefreshControl()
    let dismissButton = UIButton(type: .custom)
    var isRegistrerMode = false{
        didSet{
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
        title = "0/1000"
        mDevice.delegate = self
        if let capable = mDevice as? CHCardCapable {
            capable.registerEventDelegate(self)
        }
        mDevice.cardsModeGet(){ result in
            if case let .success(isEnabled) = result {
                self.isRegistrerMode = (isEnabled.data == 0x01)
                L.d("[NFC][isRegistrerMode:\(self.isRegistrerMode)]:")
            }
        }

        mDevice.cards(){ _ in}
        let deviceName = mDevice.getDeviceName()
        let emptyNFCHit = String(format:"co.candyhouse.sesame2.TouchEmptyNFCHint".localized,
                                 arguments:[deviceName,deviceName])
        let floatView = FloatingTipView.showIn(superView: view, style:  .textOnly(text:emptyNFCHit))
        executeOnMainThread { [weak self] in
            self?.tableView.contentInset = .init(top: floatView.FloatingHeight, left: 0, bottom: 0, right: 0)
        }
    }

    @objc func rightMenuClick() {
        mDevice.cardsModeSet(mode: isRegistrerMode ? 0x00:0x01){ [self]_ in
            isRegistrerMode = !isRegistrerMode
        }

    }

    override func viewWillDisappear(_ animated: Bool) {
        mDevice.cardsModeSet(mode: 0x00){_ in
            L.d("[NFC]viewWillDisappear ok")
        }
        if let capable = mDevice as? CHCardCapable {
            capable.unregisterEventDelegate(self)
        }
    }

    override func reloadTableView() {
        super.reloadTableView()
        executeOnMainThread {
            self.title = "\(self.mCardList.count)/1000"
        }
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        mCardList.count
    }

    @objc func imageTapped(sender: UITapGestureRecognizer) {

        guard let imageView = sender.view as? UIImageView else{
            return
        }

        guard let cell = imageView.superview?.superview?.superview  as? FingerPrintCell else {
            return
        }

        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }

        let card = mCardList[indexPath.row]
        let newCardType = (card.getCardType(level: Int(card.type)) + 1) % 3
        card.setCardType(level: newCardType)

        // Update the image based on the new cardType
        imageView.image = {
            switch newCardType {
            case 1:
                return UIImage(named: "suica")
            case 2:
                return UIImage(named: "pasmo")
            default:
                return UIImage(named: "small_icon")
            }
        }()
        self.reloadTableView()
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FingerPrintCell
        let card = mCardList[indexPath.row]
        let titleText = card.id.padding(toLength: 32, withPad: "F", startingAt: 0).noDashtoUUID()?.uuidString
        let nameText = card.name.isEmpty ? "co.candyhouse.sesame2.default_card_name".localized : card.name

        let cardType = card.getCardType(level: Int(card.type))
        cell.mImage.image = {
            switch cardType {
            case 1:
                return UIImage(named: "suica")
            case 2:
                return UIImage(named: "pasmo")
            default:
                // AppIcon是保留名称，在新版xcode 16.2编译会找不到资源，因为实施了更严格的资源命名规则
                // 后续AppIcon统一使用custom-icon
                return UIImage(named: "custom-icon")
            }
        }()
        cell.mImage.isUserInteractionEnabled = true
        cell.mImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped)))
        cell.keyName.text = nameText
        cell.keyID.text = titleText
        cell.keyID.font = UIFont.systemFont(ofSize: 9)
        cell.keyID.textColor = .secondaryLabelColor

        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var card = mCardList[indexPath.row]
        let titleText = card.id.padding(toLength: 32, withPad: "F", startingAt: 0).noDashtoUUID()?.uuidString
        let nameText = card.name.isEmpty ? "co.candyhouse.sesame2.default_card_name".localized : card.name
        let alertController = UIAlertController(title: "", message: titleText, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.TouchProCardModify".localized, style: .default) { _ in
            let renameToServer: (_ name: String, _ nameUUID: String) -> Void = { name, uuid in
                CHUserAPIManager.shared.getSubId { subId in
                    let subUUID = subId ?? ""
                    let request = CHCardNameRequest(cardType: card.type,
                                                    cardNameUUID: uuid,
                                                    subUUID: subUUID,
                                                    stpDeviceUUID: self.mDevice.deviceId.uuidString.uppercased(),
                                                    name: name,
                                                    cardID: card.id)
                    self.mDevice.cardNameSet(cardNameRequest: request){ result in
                        if case let .failure(error) = result {
                            executeOnMainThread {
                                self.view.makeToast(error.errorDescription())
                            }
                            return
                        }
                        if case .success(_) = result {
                            card.setCardName(changeName: name)
                            executeOnMainThread {
                                self.mCardList[indexPath.row] = card
                                self.reloadTableView()
                            }
                        }
                    }
                }
            }
            ChangeValueDialog.show(nameText, title: "co.candyhouse.sesame2.EditName".localized) { name in
                if BiometricData.isUUIDv4(name: card.nameUUID) {
                    renameToServer(name, card.nameUUID)
                } else {
                    let uuid = UUID().uuidString.lowercased()
                    self.mDevice.cardsChange(ID: card.id, name: uuid.replacingOccurrences(of: "-", with: "")){ _ in
                        self.mCardList.removeAll { value in
                            return value.id == card.id
                        }
                        self.reloadTableView()
                        renameToServer(name, uuid)
                    }
                }
            }
        })
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.Delete".localized, style: .destructive ) { _ in
            executeOnMainThread { [self] in
                mDevice.cardDelete(ID: card.id){ _ in }
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

    func onCardReceiveStart(device: CHSesameConnector) {
        executeOnMainThread {
            self.mCardList.removeAll()
            self.refreshControl.programaticallyBeginRefreshing(in:self.tableView)
        }
    }
    func onCardReceive(device: CHSesameConnector, id: String, name: String, type: UInt8) {
        executeOnMainThread {
            //接收卡片时，列表显示默认名称，name转为 nameUUID，用于获取后台真实的name
            if BiometricData.isUUIDv4(name: name) {
                self.mCardList.insert(SuiCard(id: id, name: "",type:type,nameUUID: name.noDashtoUUID()!.uuidString.lowercased()), at: 0)
            } else {
                self.mCardList.insert(SuiCard(id: id, name: name,type:type,nameUUID: name), at: 0)
            }
            self.reloadTableView()
        }
    }
    func onCardReceiveEnd(device: CHSesameConnector) {
        executeOnMainThread { [self] in
            self.refreshControl.programaticallyEndRefreshing(in:self.tableView)
            self.reloadTableView()
            guard let capable = device as? CHCardCapable else {
                return
            }
            capable.postAuthenticationData(SuiCard.toBiometricListDataWarpper(mDevice.deviceId.uuidString, mCardList)) { response in
                if case let .success(data) = response {
                    self.mCardList = BiometricData.toSuiCardList(items: data.data)
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

    func onCardChanged(device: CHSesameConnector, id: String, name: String, type: UInt8) {
        var card = SuiCard(id: id, name: name, type: type, nameUUID: name)
        if BiometricData.isUUIDv4(name: name) {
            card = SuiCard(id: id, name: "", type: type, nameUUID: name.noDashtoUUID()!.uuidString.lowercased())
        }
        self.mCardList.insert(card, at: 0)
        executeOnMainThread {
            self.reloadTableView()
            guard let capable = device as? CHCardCapable else {
                return
            }
            capable.putAuthenticationData(SuiCard.toBiometricDataWarpper(self.mDevice.deviceId.uuidString, card)) { response in
                if case let .failure(error) = response {
                    executeOnMainThread {
                        self.view.makeToast(error.errorDescription())
                    }
                }
            }
        }
    }
    
    func onCardModeChanged(mode: UInt8) {
        executeOnMainThread {
            self.isRegistrerMode = (mode == 0x01)
        }
    }
    
    func onCardDelete(device: CHSesameConnector, id: String) {
        executeOnMainThread {
            if let index = self.mCardList.firstIndex(where: { $0.id.lowercased() == id.lowercased() }) {
                let removedCard = self.mCardList.remove(at: index)
                self.deleteCardFromServer(removedCard)
                self.reloadTableView()
            }
        }
    }
    
    func deleteCardFromServer(_ card: SuiCard) {
        guard let capable = mDevice as? CHCardCapable else {
            return
        }
        capable.deleteAuthenticationData(SuiCard.toBiometricDataWarpper(self.mDevice.deviceId.uuidString, card)) { response in
            if case let .failure(error) = response {
                executeOnMainThread {
                    self.view.makeToast(error.errorDescription())
                }
            }
        }
    }

}
