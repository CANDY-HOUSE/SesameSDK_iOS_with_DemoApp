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

    func setCardType(level: Int) {
        UserDefaults.standard.set(level, forKey: self.id)
    }

    func getCardType(level: Int) -> Int {
        return UserDefaults.standard.integer(forKey: self.id)
    }
}

extension NFCCardVC {
    static func instance(_ device: CHSesameTouchPro) -> NFCCardVC {
        let vc = NFCCardVC(nibName: nil, bundle: nil)
        vc.mDevice = device
        return vc
    }
}


class NFCCardVC: CHBaseTableVC ,CHSesameTouchProDelegate, CHDeviceStatusDelegate{

    var mDevice: CHSesameTouchPro!
    var mCardList = [SuiCard]()
    var refreshControl: UIRefreshControl = UIRefreshControl()
    let dismissButton = UIButton(type: .custom)
    var isRegistrerMode = false{
        didSet{
            DispatchQueue.main.async { [self] in
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
        setupEmptyDataView("co.candyhouse.sesame2.TouchEmptyNFCHint".localized)

        let dismissButtonItem = UIBarButtonItem(customView: dismissButton)
        dismissButtonItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        dismissButtonItem.customView?.heightAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButtonItem.customView?.widthAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButton.addTarget(self, action: #selector(rightMenuClick), for: .touchUpInside)
        navigationItem.rightBarButtonItem = dismissButtonItem
        title = "0/100"
        mDevice.cardsModeGet(){ result in
            if case let .success(isEnabled) = result {
                self.isRegistrerMode = (isEnabled.data == 0x01)
                L.d("[NFC][isRegistrerMode:\(self.isRegistrerMode)]:")
            }
        }

        mDevice.cards(){ _ in}
        mDevice.delegate = self

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
    }

    override func reloadTableView() {
        super.reloadTableView()
        DispatchQueue.main.async {
            self.title = "\(self.mCardList.count)/100"
        }
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        mCardList.count
    }

    @objc func imageTapped(sender: UITapGestureRecognizer) {

        guard let imageView = sender.view as? UIImageView else{
            return
        }

        guard let cell = imageView.superview?.superview?.superview?.superview  as? FingerPrintCell else {
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
                return UIImage(named: "AppIcon")
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
        let card = mCardList[indexPath.row]
        let titleText = card.id.padding(toLength: 32, withPad: "F", startingAt: 0).noDashtoUUID()?.uuidString
        let nameText = card.name.isEmpty ? "co.candyhouse.sesame2.default_card_name".localized : card.name
        let alertController = UIAlertController(title: "", message: titleText, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.TouchProCardModify".localized, style: .default) { _ in
            executeOnMainThread {
                ChangeValueDialog.show(nameText, title: "co.candyhouse.sesame2.EditName".localized) { name in
                    self.mDevice.cardsChange(ID: card.id, name: name){ _ in
                        self.mCardList.removeAll { value in
                            return value.id == card.id
                        }
                        self.reloadTableView()
                    }
                }
            }
        })
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.Delete".localized, style: .destructive ) { _ in
            executeOnMainThread { [self] in
                mDevice.cardsDelete(ID: card.id){ _ in
                    self.mCardList.removeAll { value in
                        return value.id == card.id
                    }
                    //                    self.mCardList.remove(at: indexPath.row)
                    self.reloadTableView()

                }
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
        DispatchQueue.main.async {
            self.mCardList.removeAll()
            self.refreshControl.programaticallyBeginRefreshing(in:self.tableView)
        }
    }
    func onCardReceive(device: CHSesameConnector, id: String, name: String, type: UInt8) {
        DispatchQueue.main.async {
            self.mCardList.insert(SuiCard(id: id, name: name,type:type), at: 0)
            self.reloadTableView()
        }
    }
    func onCardReceiveEnd(device: CHSesameConnector) {
        DispatchQueue.main.async {
            self.refreshControl.programaticallyEndRefreshing(in:self.tableView)
            self.reloadTableView()
        }
    }

    func onCardChanged(device: CHSesameConnector, id: String, name: String, type: UInt8) {
        DispatchQueue.main.async {
            self.mCardList.insert(SuiCard(id: id, name: name,type: type), at: 0)
            self.reloadTableView()
        }
    }

}
