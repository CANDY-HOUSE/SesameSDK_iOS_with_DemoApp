//
//  FingerPrintListVC.swift
//  SesameUI
//  Created by tse on 2023/5/17.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
struct FingerPrint {
    var id: String
    var name: String
}
extension FingerPrintListVC {
    static func instance(_ device: CHSesameTouchPro) -> FingerPrintListVC {
        let vc = FingerPrintListVC(nibName: nil, bundle: nil)
        vc.mDevice = device
        return vc
    }
}

class FingerPrintListVC: CHBaseTableVC ,CHSesameTouchProDelegate, CHDeviceStatusDelegate{

    var mDevice: CHSesameTouchPro!
    var fingerPrints = [FingerPrint]()
    var refreshControl: UIRefreshControl = UIRefreshControl()
    let dismissButton = UIButton(type: .custom)
    var isRegistrerMode = false{
        didSet{
            DispatchQueue.main.async {
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
        navigationBarBackgroundColor = .white
        tableView.register(UINib(nibName: "FingerPrintCell", bundle: nil), forCellReuseIdentifier: "cell")
        tableView.refreshControl = refreshControl
        tableView.bounces = false
        setupEmptyDataView("co.candyhouse.sesame2.TouchEmptyFingerHint".localized)

        let dismissButtonItem = UIBarButtonItem(customView: dismissButton)
        dismissButtonItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        dismissButtonItem.customView?.heightAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButtonItem.customView?.widthAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButton.addTarget(self, action: #selector(rightMenuClick), for: .touchUpInside)
        navigationItem.rightBarButtonItem = dismissButtonItem
        title = "0/100"
        mDevice.fingerPrintModeGet(){ result in
            if case let .success(isEnabled) = result {
                self.isRegistrerMode = (isEnabled.data == 0x01)
                L.d("[FG][isRegistrerMode:\(self.isRegistrerMode)]:")
            }
        }
        mDevice.fingerPrints(){ _ in}
        mDevice.delegate = self
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
        let card = fingerPrints[indexPath.row]
        let titleNumber = Int(Data(hex: card.id)[0]) + 1
        let titleText = String(format: "%03d", titleNumber)
        
        let nameText = card.name.isEmpty ? "co.candyhouse.sesame2.default_fingerprint_name".localized : card.name

        let alertController = UIAlertController(title: "", message: titleText, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.TouchProFingerModify".localized, style: .default) { _ in
            executeOnMainThread {
                ChangeValueDialog.show(nameText, title: "co.candyhouse.sesame2.EditName".localized) { name in
                    self.mDevice.fingerPrintsChange(ID: card.id, name: name){ _ in
                        self.fingerPrints.removeAll { value in
                            return value.id == card.id
                        }
                        self.reloadTableView()
                    }
                }
            }
        })
        
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.TouchProFingerDelete".localized, style: .destructive ) { _ in
            executeOnMainThread { [self] in
                mDevice.fingerPrintDelete(ID: card.id){ _ in
                    L.d("fingerPrintDelete!!!")
                    self.fingerPrints.removeAll { value in
                        return value.id == card.id
                    }
                    //                    self.fingerPrints.remove(at: indexPath.row)
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

    func onFingerPrintReceiveStart(device: CHSesameConnector) {
        DispatchQueue.main.async {
            self.fingerPrints.removeAll()
            self.refreshControl.programaticallyBeginRefreshing(in:self.tableView)
        }
    }
    
    func onFingerPrintReceive(device: CHSesameConnector, id: String, name: String, type: UInt8) {
        DispatchQueue.main.async {
            self.fingerPrints.insert(FingerPrint(id: id, name: name), at: 0)
            self.reloadTableView()
        }

    }
    func onFingerPrintReceiveEnd(device: CHSesameConnector) {
        DispatchQueue.main.async {
            self.refreshControl.programaticallyEndRefreshing(in:self.tableView)
            self.reloadTableView()
        }
    }
    
    func onFingerPrintChanged(device: CHSesameConnector, id: String, name: String, type: UInt8) {
//        L.d("[FG][onFingerPrintChanged] \(id):\(name)")
        DispatchQueue.main.async {
            self.fingerPrints.insert(FingerPrint(id: id, name: name), at: 0)
            self.reloadTableView()
        }
    }
    
    override func reloadTableView() {
        super.reloadTableView()
        DispatchQueue.main.async {
            self.title = "\(self.fingerPrints.count)/100"
        }
    }

}
