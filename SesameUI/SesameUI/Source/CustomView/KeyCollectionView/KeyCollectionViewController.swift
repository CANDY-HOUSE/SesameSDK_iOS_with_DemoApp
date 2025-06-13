//
//  KeyCollectionViewController.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/11/18.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import AWSMobileClientXCF

private let reuseIdentifier = "Cell"
private let reuseIdentifierAdd = "AddCell"

protocol KeyCollectionViewControllerDelegate: AnyObject {
    func collectionViewHeightDidChanged(_ height: CGFloat)
    func noPermission()
}

class KeyCollectionViewData {
    // Owner, Manager, Guest
    var guestKeys = [CHGuestKey]()
    var members = [CHUser]()
    
    class GuestKeyGroup {
        var guestKey: CHGuestKey?
        var deviceMemebers = [CHUser]()
        let gtag: String
        
        init(gtag: String, guestKey: CHGuestKey? = nil, deviceMemebers: [CHUser] = [CHUser]()) {
            self.gtag = gtag
            self.guestKey = guestKey
            self.deviceMemebers = deviceMemebers
        }
    }
    
    func sortedMembers(_ topSubId: String?) -> [Any] {
        var mySelf = [CHUser]()
        var friends = [CHUser]()
        if let subId = topSubId {
            mySelf = members.filter({ $0.subId == UUID(uuidString: subId )})
            friends = members.filter({ $0.subId != UUID(uuidString: subId )})
        } else {
            friends = members
        }
        friends = friends.sorted(by: { lhs, rhs -> Bool in
            lhs.subId.uuidString < rhs.subId.uuidString
        })
        
        let guestKeyGroup = guestKeys.sorted(by: { lhs, rhs -> Bool in
            lhs.guestKeyId < rhs.guestKeyId
        }).map { guestKey -> GuestKeyGroup in
            let guestUsers = friends.filter({ $0.keyLevel == KeyLevel.guest.rawValue && $0.gtag == guestKey.guestKeyId.substring(from: 16) })
            return GuestKeyGroup(gtag: guestKey.guestKeyId.substring(from: 16), guestKey: guestKey, deviceMemebers: guestUsers)
        }
        var flatGuestKeyGroup = [Any]()
        // Guests have guest key
        for guestKey in guestKeyGroup {
            flatGuestKeyGroup.append(guestKey.guestKey!)
            flatGuestKeyGroup += guestKey.deviceMemebers
        }
        
        return mySelf +
        friends.filter({ $0.keyLevel == KeyLevel.owner.rawValue }).sorted(by: { lhs, rhs -> Bool in lhs.subId.uuidString < rhs.subId.uuidString}) +
        friends.filter({ $0.keyLevel == KeyLevel.manager.rawValue }).sorted(by: { lhs, rhs -> Bool in lhs.subId.uuidString < rhs.subId.uuidString}) +
            flatGuestKeyGroup
    }
}

class KeyCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var subId: String?
    var device: CHDevice!
    var deviceMemberViewModel = KeyCollectionViewData()
    weak var delegate: KeyCollectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(UINib(nibName: "KeyCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifierAdd)
        collectionView.register(UINib(nibName: "KeyCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        
        CHUserAPIManager.shared.getSubId { subId in
            self.subId = subId
            self.getMembers()
            L.d("[KeyCollectionViewController] getSubId success")
        }
    }
    
    func getMembers() {
        guard AWSMobileClient.default().currentUserState == .signedIn else {
            self.getGuestKeys()
            return
        }
        executeOnMainThread {
            ViewHelper.showLoadingInView(view: self.view)
        }
        CHUserAPIManager.shared.getSubId { subId in
            self.subId = subId
            CHUserAPIManager.shared.getDeviceMembers(self.device.deviceId.uuidString) { result in
                switch result {
                case .success(let users):
                    L.d("[KeyCollectionViewController] getDeviceMembers success")
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
                    }
                    self.deviceMemberViewModel.members = users.data
                    self.getGuestKeys()
                    
                case .failure(let error):
                    executeOnMainThread {
                        if (error as NSError).code == 403 {
                            self.delegate?.noPermission()
                        }
                        ViewHelper.hideLoadingView(view: self.view)
                    }
                }
            }
        }
    }
    
    func getGuestKeys() {
        executeOnMainThread {
            ViewHelper.showLoadingInView(view: self.view)
        }
        device.getGuestKeys { result in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.view)
                if case let .success(guestKey) = result {
                    self.deviceMemberViewModel.guestKeys = guestKey.data
                    self.reloadCollectionView()
                } else {
                    self.deviceMemberViewModel.guestKeys = []
                    self.reloadCollectionView()
                }
            }
        }
    }
    
    func reloadCollectionView() {
        self.collectionView.reloadData()
        self.delegate?.collectionViewHeightDidChanged(self.collectionView.collectionViewLayout.collectionViewContentSize.height)
    }
    
    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1 + deviceMemberViewModel.sortedMembers(self.subId).count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 { // AddButton
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifierAdd, for: indexPath) as! KeyCollectionViewCell
            cell.nameLabel.text = ""
            cell.avatarView.image = UIImage.SVGImage(named: "plus", fillColor: .gray)
            cell.avatarBackgroundView.backgroundColor = .clear
            cell.avatarTrailing.constant = 15
            cell.avatarTop.constant = 15
            cell.avatarLeading.constant = 15
            cell.avatarBottom.constant = 15
            cell.keyLevelLabel.text = ""
            let dashBorder = CAShapeLayer()
            dashBorder.strokeColor = UIColor.gray.cgColor
            dashBorder.lineWidth = 2.0
            dashBorder.lineDashPattern = [5, 5]
            dashBorder.frame = cell.avatarBackgroundView!.bounds
            dashBorder.backgroundColor = UIColor.clear.cgColor
            dashBorder.fillColor = nil
            dashBorder.accessibilityLabel = "dashBorder"
            dashBorder.path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: 40, height: 40)).cgPath
            cell.avatarBackgroundView!.layer.addSublayer(dashBorder)
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! KeyCollectionViewCell
        cell.avatarContainerView.backgroundColor = .white
        cell.avatarBackgroundView.backgroundColor = .sesame2Gray
        cell.keyLevelLabel.font = UIFont.boldSystemFont(ofSize: 10)
        cell.avatarContainerView.layer.masksToBounds = true
        cell.avatarContainerView.layer.cornerRadius = 0.0
        
        let index = indexPath.row - 1 // - AddButton
        let memebers = self.deviceMemberViewModel.sortedMembers(self.subId)
        let member = memebers[index]
        
        if let chUser = member as? CHUser {
            cell.nameLabel.text = chUser.nickname ?? chUser.email
            //            cell.keyLevelLabel.textColor = chUser.keyLevel!.color()
            cell.keyLevelLabel.text = chUser.keyLevel != KeyLevel.guest.rawValue ? KeyLevel(rawValue: chUser.keyLevel!)!.description() : ""
            cell.avatarView.image = UIImage.SVGImage(named: "man")
            
            if let gtag = chUser.gtag {
                
                let checkBefore = checkNeedRoundBefore(gtag: gtag, index: index)
                let checkAfter = checkNeedRoundAfter(gtag: gtag, index: index)
                cell.avatarContainerView.layer.masksToBounds = true
                
                if checkBefore == true && checkAfter == true {
                    cell.avatarContainerView.layer.cornerRadius = 5.0
                    cell.avatarContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                } else if checkBefore == false && checkAfter == true {
                    cell.avatarContainerView.layer.cornerRadius = 5.0
                    cell.avatarContainerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
                } else if checkBefore == true && checkAfter == false {
                    cell.avatarContainerView.layer.cornerRadius = 5.0
                    cell.avatarContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
                } else if checkBefore == false && checkAfter == false {
                    cell.avatarContainerView.layer.cornerRadius = 0.0
                }
                
                let hexColor = gtag.substring(from: gtag.count - 6)
                cell.avatarBackgroundView.backgroundColor = .sesame2Gray
                cell.avatarContainerView.backgroundColor = UIColor(hexString: hexColor).lighter()
            }
            return cell
        }
        
        if let guestKey = member as? CHGuestKey {
            let hexColor = guestKey.guestKeyId.substring(from: guestKey.guestKeyId.count - 6)
            cell.avatarBackgroundView.backgroundColor = .sesame2Gray
            cell.avatarContainerView.backgroundColor = UIColor(hexString: hexColor).lighter()
            
            cell.nameLabel.text = guestKey.keyName
            cell.keyLevelLabel.text = KeyLevel.guest.description()
            cell.avatarView.image = UIImage.SVGImage(named: "guestKey")
            
            let checkBefore = checkNeedRoundBefore(gtag: guestKey.guestKeyId.substring(from: 16), index: index)
            let checkAfter = checkNeedRoundAfter(gtag: guestKey.guestKeyId.substring(from: 16), index: index)
            cell.avatarContainerView.layer.masksToBounds = true
            
            if checkBefore == true && checkAfter == true {
                cell.avatarContainerView.layer.cornerRadius = 5.0
                cell.avatarContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            } else if checkBefore == false && checkAfter == true {
                cell.avatarContainerView.layer.cornerRadius = 5.0
                cell.avatarContainerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            } else if checkBefore == true && checkAfter == false {
                cell.avatarContainerView.layer.cornerRadius = 5.0
                cell.avatarContainerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            } else if checkBefore == false && checkAfter == false {
                cell.avatarContainerView.layer.cornerRadius = 0.0
            }
        }
        return cell
    }
    
    func checkNeedRoundBefore(gtag: String, index: Int) -> Bool {
        let members = self.deviceMemberViewModel.sortedMembers(self.subId)
        if index == 0 {
            return true
        } else if index-1 >= 0, let previousCHUser = members[index-1] as? CHUser {
            return previousCHUser.gtag != gtag
        } else if index-1 >= 0, let previousGuestKey = members[index-1] as? CHGuestKey {
            return previousGuestKey.guestKeyId.substring(from: 16) != gtag
        }
        return false
    }
    
    func checkNeedRoundAfter(gtag: String, index: Int) -> Bool {
        let members = self.deviceMemberViewModel.sortedMembers(self.subId)
        if index == members.count - 1 {
            return true
        } else if index+1 < members.count, let nextCHUser = members[index+1] as? CHUser {
            return nextCHUser.gtag != gtag
        } else if index+1 < members.count, let nextGuestKey = members[index+1] as? CHGuestKey {
            return nextGuestKey.guestKeyId.substring(from: 16) != gtag
        }
        return false
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if UIScreen.main.traitCollection.userInterfaceIdiom == .pad {
            return CGSize(width: (view.frame.width / 13), height: 90)
        }
        return CGSize(width: (view.frame.width / 7), height: 90)
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            navigateToFriendSelection()
            return
        }
        
        let index = indexPath.row - 1 // - AddButton
        guard index != 0 else { return } // 點自己不顯示選項
        
        let member = self.deviceMemberViewModel.sortedMembers(self.subId)[index]
        if let friend = member as? CHUser, device.keyLevel <= friend.keyLevel! {
            let message = String(format: "co.candyhouse.sesame2.revokeKeyOfFriend".localized, arguments: [friend.email])
            let alertController = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
            
            let revoke = UIAlertAction(title: "co.candyhouse.sesame2.revoke".localized, style: .destructive) { _ in
                ViewHelper.showLoadingInView(view: self.view)
                CHUserAPIManager.shared.revokeKey(self.device.deviceId.uuidString, ofFriend: friend.subId.uuidString) { result in
                    if case .failure(_) = result {
                        executeOnMainThread {
                            ViewHelper.hideLoadingView(view: self.view)
                            self.deviceMemberViewModel.members.removeAll { // 操作失败，刷新列表
                                $0.subId == friend.subId
                            }
                            self.reloadCollectionView()
                        }
                    } else {
                        executeOnMainThread {
                            ViewHelper.hideLoadingView(view: self.view)
                            self.deviceMemberViewModel.members.removeAll {
                                $0.subId == friend.subId
                            }
                            self.reloadCollectionView()
                        }
                    }
                }
            }
            
            let cancel = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil)
            alertController.addAction(revoke)
            alertController.addAction(cancel)
            alertController.popoverPresentationController?.sourceView = collectionView.cellForItem(at: indexPath)
            present(alertController, animated: true, completion: nil)
        }
        
        if let guestKey = member as? CHGuestKey {
            guestKeyDidSelected(guestKey, atIndex: indexPath)
        }
    }
    
    func guestKeyDidSelected(_ guestKey: CHGuestKey, atIndex indexPath: IndexPath) {
        let alertController = UIAlertController(title: "", message: guestKey.keyName, preferredStyle: .actionSheet)
        let modifyName = UIAlertAction(title: "co.candyhouse.sesame2.modifyGuestKeyTag".localized, style: .default) { _ in
            self.presentCHAlertWithPlaceholder(title: "co.candyhouse.sesame2.modifyGuestKeyTag".localized, placeholder: guestKey.keyName ?? "", hint: "") { newValue in
                ViewHelper.showLoadingInView(view: self.view)
                self.device.updateGuestKey(guestKey.guestKeyId, name: newValue) { result in
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
                        if case let .failure(error) = result {
                            self.view.makeToast(error.errorDescription())
                        } else {
                            for (index, element) in self.deviceMemberViewModel.guestKeys.enumerated() {
                                if element.guestKeyId == guestKey.guestKeyId {
                                    self.deviceMemberViewModel.guestKeys[index].keyName = newValue
                                }
                            }
                            self.reloadCollectionView()
                        }
                    }
                }
            }
        }
        
        let showQRCode = UIAlertAction(title: "co.candyhouse.sesame2.ShareTheKey".localized, style: .default) { _ in
            let qrCode = URL.qrCodeURLFromDevice(self.device, deviceName: guestKey.keyName ?? "", keyLevel: KeyLevel.guest.rawValue, guestKey: guestKey.guestKeyId)
            let sesame2QRCodeViewController = QRCodeViewController.instanceWithCHDevice(self.device, qrCode: qrCode!) {
                executeOnMainThread {
                    self.getMembers()
                }
            }
            self.navigationController?.pushViewController(sesame2QRCodeViewController, animated: true)
        }
        
        let revokeKey = UIAlertAction(title: "co.candyhouse.sesame2.revoke".localized, style: .destructive) { _ in
            ViewHelper.showLoadingInView(view: self.view)
            self.device.removeGuestKey(guestKey.guestKeyId) { result in
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
                    if case let .failure(error) = result {
                        self.view.makeToast(error.errorDescription())
                    } else {
                        self.deviceMemberViewModel.guestKeys.removeAll(where: { $0.guestKeyId == guestKey.guestKeyId })
                        self.deviceMemberViewModel.members.removeAll { $0.gtag == guestKey.guestKeyId.substring(from: 16) }
                        self.reloadCollectionView()
                    }
                }
            }
        }
        
        let cancel = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel) { _ in
            
        }
        
        alertController.addAction(modifyName)
        alertController.addAction(showQRCode)
        alertController.addAction(revokeKey)
        alertController.addAction(cancel)
        alertController.popoverPresentationController?.sourceView = collectionView.cellForItem(at: indexPath)!
        present(alertController, animated: true, completion: nil)
    }
    
    func navigateToFriendSelection() {
        let friendListViewController = FriendListViewController.instance(popupMenu: false) { [weak self] user, view in
            guard let self = self else { return }
            self.didSelectTableItem(user!, view!)
        }
        navigationController?.pushViewController(friendListViewController, animated: true)
    }
}

extension KeyCollectionViewController: ShareAlertConfigurator {
    func didSelectTableItem(_ friend: CHUser, _ view: UIView) {
        modalSheetOnFriendsByRoleLevel(device: self.device, friend: friend, view: view) { isSuccess in
//            if isSuccess {
                self.getMembers() // 2014-01-31無論成功/失敗均刷新頁面
//            }
        }
    }
}

extension KeyCollectionViewController {
    static func instanceWithDevice(_ device: CHDevice) -> KeyCollectionViewController {
        let keyCollectionViewController = KeyCollectionViewController.init(nibName: "KeyCollectionViewController", bundle: nil)
        keyCollectionViewController.device = device
        return keyCollectionViewController
    }
}
