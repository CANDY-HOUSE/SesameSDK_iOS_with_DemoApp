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
}

extension PassCodeVC {
    static func instance(_ device: CHSesameTouchPro) -> PassCodeVC {
        let vc = PassCodeVC(nibName: nil, bundle: nil)
        vc.mDevice = device
        return vc
    }
}


class PassCodeVC: CHBaseTableVC ,CHSesameTouchProDelegate, CHDeviceStatusDelegate{

    var mDevice: CHSesameTouchPro!
    var mPassCodeList = [KeyboardPassCode]()
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

        let dismissButtonItem = UIBarButtonItem(customView: dismissButton)
        dismissButtonItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        dismissButtonItem.customView?.heightAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButtonItem.customView?.widthAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButton.addTarget(self, action: #selector(rightMenuClick), for: .touchUpInside)
        navigationItem.rightBarButtonItem = dismissButtonItem
        setupEmptyDataView("co.candyhouse.sesame2.TouchEmptyPasscodeHint".localized)
        title = "0/100"
        mDevice.passCodeModeGet(){ result in
            if case let .success(isEnabled) = result {
                self.isRegistrerMode = (isEnabled.data == 0x01)
                L.d("[NFC][isRegistrerMode:\(self.isRegistrerMode)]:")
            }
        }

        mDevice.passCodes(){ _ in}
        mDevice.delegate = self

    }

    @objc func rightMenuClick() {
        mDevice.passCodeModeSet(mode: isRegistrerMode ? 0x00:0x01){ [self]_ in
            isRegistrerMode = !isRegistrerMode
        }
    }


    override func viewWillDisappear(_ animated: Bool) {
        mDevice.passCodeModeSet(mode: 0x00){_ in  }
    }

    override func reloadTableView() {
        super.reloadTableView()
        DispatchQueue.main.async {
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
        let card = mPassCodeList[indexPath.row]
        let titleText = card.id.hexStringToIntStr()
        let nameText = card.name.isEmpty ? "co.candyhouse.sesame2.default_passcode_name".localized : card.name
        let alertController = UIAlertController(title: "", message: titleText, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.TouchProPWDModify".localized, style: .default) { _ in
            executeOnMainThread {
                ChangeValueDialog.show(nameText, title: "co.candyhouse.sesame2.EditName".localized) { name in
                    self.mDevice.passCodeChange(ID: card.id, name: name){ _ in
                        self.mPassCodeList.removeAll { value in
                            return value.id == card.id
                        }
                        self.reloadTableView()
                    }
                }
            }
        })
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.Delete".localized, style: .destructive ) { _ in
            executeOnMainThread { [self] in
                mDevice.passCodeDelete(ID: card.id){ _ in
//                    self.mPassCodeList.removeAll { value in
//                        return value.id == card.id
//                    }
                    self.mPassCodeList.remove(at: indexPath.row)
                    self.reloadTableView()

                }
            }
        })
        let cancel = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil)
        alertController.addAction(cancel)
        alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
        present(alertController, animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 100 }

    func onPassCodeReceiveStart(device: CHSesameConnector) {
        DispatchQueue.main.async {
            self.mPassCodeList.removeAll()
            self.refreshControl.programaticallyBeginRefreshing(in:self.tableView)
        }
    }
    func onPassCodeReceive(device: CHSesameConnector, id: String, name: String, type: UInt8) {
        DispatchQueue.main.async {
            self.mPassCodeList.insert(KeyboardPassCode(id: id, name: name), at: 0)
            self.reloadTableView()
        }
    }
    func onPassCodeReceiveEnd(device: CHSesameConnector) {
        DispatchQueue.main.async {
            self.refreshControl.programaticallyEndRefreshing(in:self.tableView)
            self.reloadTableView()
        }
    }

    func onPassCodeChanged(device: CHSesameConnector, id: String, name: String, type: UInt8) {
        DispatchQueue.main.async {
            self.mPassCodeList.insert(KeyboardPassCode(id: id, name: name), at: 0)
            self.reloadTableView()
        }
    }

}
