//
//  FriendKeyListViewController.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/11/17.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

private let cellIdentifier = "cell"
private let cellHeight = CGFloat(50)

class FriendKeyListViewController: CHBaseViewController, UICollectionViewDelegateFlowLayout {
    var devices = [CHUserKey]()
    var friend: CHUser!
    let scrollView = UIScrollView(frame: .zero)
    var emailView: CHUIPlainSettingView!
    let contentStackView = UIStackView(frame: .zero)
    var sesame2ListView = UITableView(frame: .zero)
    var sesame2ListViewHeight: NSLayoutConstraint!
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var completeHandler: ((_ isDeleteFriend: Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .sesame2Gray
        scrollView.addSubview(contentStackView)
        view.addSubview(scrollView)
        refreshControl.attributedTitle = NSAttributedString(string: "co.candyhouse.sesame2.PullToRefresh".localized)
        refreshControl.addTarget(self, action: #selector(getKeys), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 0
        contentStackView.distribution = .fill
        UIView.autoLayoutStackView(contentStackView, inScrollView: scrollView)
        sesame2ListView.delegate = self
        sesame2ListView.dataSource = self
        sesame2ListView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        sesame2ListView.isScrollEnabled = false
        sesame2ListView.backgroundColor = .white
        arrangeSubviews()
        getKeys()
        title = friend.nickname ?? friend.email
    }
    
    func arrangeSubviews() {
        // MARK: Email
        let emailView = CHUIViewGenerator.plain() { [weak self] sender,event in
            guard let self = self else { return }
            self.emailView.showCopyMenu {
                return self.emailView.value
            }
        }
        emailView.title = "co.candyhouse.sesame2.Email".localized
        emailView.value = friend.email
        self.emailView = emailView
        contentStackView.addArrangedSubview(emailView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .group))
        
        // MARK: Sesame2 List Title
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = "co.candyhouse.sesame2.friendsKeys".localized
        titleLabel.numberOfLines = 0 // 設置為0時，允許無限換行
        titleLabel.lineBreakMode = .byWordWrapping // 按單詞換行
        titleLabel.textColor = UIColor.placeHolderColor
        titleLabelContainer.addSubview(titleLabel)
        titleLabel.autoPinLeading(constant: 10)
        titleLabel.autoPinTrailing(constant: -10)
        titleLabel.autoPinTop()
        titleLabel.autoPinBottom()
        contentStackView.addArrangedSubview(titleLabelContainer)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        // MARK: Sesame2 List
        let sesame2ListContainer = UIView(frame: .zero)
        sesame2ListContainer.addSubview(sesame2ListView)
        contentStackView.addArrangedSubview(sesame2ListContainer)
        sesame2ListViewHeight = sesame2ListView.autoLayoutHeight(0)
        sesame2ListView.autoPinEdgesToSuperview()
        
        // MARK: Add Sesame Button
        let addSesameButton = CHUIViewGenerator.plain { [unowned self] button,_ in
            self.addSesameTapped(button)
        }
        addSesameButton.title = "co.candyhouse.sesame2.shareSesameToFriends".localized
        contentStackView.addArrangedSubview(addSesameButton)
        
        // MARK: Drop key
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .group))
        let dropKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.removeFriend(sender as! UIButton)
        }
        dropKeyView.title = "co.candyhouse.sesame2.DeleteFriend".localized
        contentStackView.addArrangedSubview(dropKeyView)
    }
    
    @objc
    func getKeys(showLoading: Bool = true) {
        if showLoading {
            ViewHelper.showLoadingInView(view: self.view)
        }
        CHUserAPIManager.shared.getUserKeysOfFriend(friend.subId.uuidString) { result in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.view)
                self.refreshControl.endRefreshing()
            }
            switch result {
            case .success(let keys):
                executeOnMainThread {
                    self.devices = keys.data
                    self.sesame2ListViewHeight.constant = CGFloat(self.devices.count) * cellHeight
                    self.sesame2ListView.reloadData()
                }
            case .failure(let error):
                executeOnMainThread {
                    self.view.makeToast(error.errorDescription())
                }
            }
        }
    }
    
    @objc
    func removeFriend(_ sender: Any) {
        let trashKey = UIAlertAction(title: "co.candyhouse.sesame2.DeleteFriend".localized,
                                     style: .destructive) { (action) in
            ViewHelper.showLoadingInView(view: self.view)
            CHUserAPIManager.shared.deleteFriend(self.friend.subId.uuidString) { result in
                switch result {
                case .success(_):
                    executeOnMainThread {
                        self.navigationController?.popToRootViewController(animated: false)
                        self.completeHandler?(true)
                    }
                case .failure(let error):
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
                        self.view.makeToast(error.errorDescription())
                    }
                }
            }
        }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(trashKey)
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized,style: .cancel) { (action) in})
        alertController.popoverPresentationController?.sourceView = sender as! UIButton
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func addSesameTapped(_ sender: Any) {
        let wifiModule2KeysListViewController = FriendKeyShareSelectionViewController.instanceWithFriend(friend) {
            executeOnMainThread {
                self.getKeys()
            }
        }
        present(wifiModule2KeysListViewController.navigationController!, animated: true, completion: nil)
    }
}

extension FriendKeyListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { devices.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let userKey = devices[indexPath.row]
        let cell =   UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        cell.accessoryView = UIImageView(image: UIImage.SVGImage(named: "delete", fillColor: .gray))
        cell.selectionStyle = .none
        cell.textLabel?.text = userKey.deviceName
        cell.detailTextLabel?.textColor = .secondaryLabelColor
        cell.detailTextLabel?.text =  KeyLevel(rawValue: userKey.keyLevel!)?.description()
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { cellHeight }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = devices[indexPath.row]
        var myDevice: CHDevice?
        CHDeviceManager.shared.getCHDevices { result in
            if case let .success(devices) = result {
                myDevice = (devices.data.filter {
                    $0.deviceId.uuidString == device.deviceUUID
                }.first)
            }
        }
        // This device is not existing in local db.
        guard let foundDevice = myDevice else {return}
        if(foundDevice.keyLevel < 0){return}

        if(foundDevice.keyLevel <= device.keyLevel!){
            /// 有足夠權限 ex owner:0  <= (owner:0/manager:1)
        }else{
            return
        }

        var deviceName = device.deviceUUID
        if let chDevice = device.toCHDevice() {
            deviceName = chDevice.deviceName
        }
        
        let message = String(format: "co.candyhouse.sesame2.revokeKeyOfFriend".localized, arguments: [deviceName])
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.revoke".localized, style: .destructive) { _ in
            ViewHelper.showLoadingInView(view: self.view)
            CHUserAPIManager.shared.revokeKey(device.deviceUUID, ofFriend: self.friend.subId.uuidString) { result in
                executeOnMainThread {
                    self.getKeys(showLoading: false)
                }
            }
        })
        alertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil))
        alertController.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
        present(alertController, animated: true, completion: nil)
    }
}

extension FriendKeyListViewController {
    static func instance(_ friend: CHUser, completeHandler: ((_ isDeleteFriend: Bool) -> Void)? = nil) -> FriendKeyListViewController {
        let vc = FriendKeyListViewController(nibName: nil, bundle: nil)
        vc.friend = friend
        vc.completeHandler = completeHandler
        vc.hidesBottomBarWhenPushed = true
        return vc
    }
}
