//
//  MeViewController.swift
//  SesameUI
//  [joi] [logout] 觀察
//  Created by Wayne Hsiao on 2020/9/14.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import AWSMobileClientXCF

extension MeViewController {
    static func instance() -> MeViewController {
        let meViewController = MeViewController(nibName: nil, bundle: nil)
        let _ = UINavigationController(rootViewController: meViewController)
        return meViewController
    }
}

class MeViewController: CHBaseViewController {
    
    var userState: UserState = .unknown
    
    // MARK: - UI component
    lazy var userNameView: HistoryTagView = {
        let nib = Bundle.main.loadNibNamed("HistoryTagView", owner: nil, options: nil)
        let historyTagView = nib!.first as! HistoryTagView
        historyTagView.titleLabel.text = "co.candyhouse.sesame2.LogIn".localized + "/" + "co.candyhouse.sesame2.SignUp".localized
        historyTagView.historyTagButton.addTarget(self, action: #selector(changeNameTapped), for: .touchUpInside)
        historyTagView.qrCodeButton.addTarget(self, action: #selector(shareUser), for: .touchUpInside)
        historyTagView.qrCodeImageView.image = UIImage(named: "qr-code")!
        return historyTagView
    }()

    var userStateView = UILabel(frame: .zero)
    var logOutView: CHUICallToActionView?
    var delAccountView: CHUICallToActionView?
    let contentView = UIStackView(frame: .zero)
    let scrollView = UIScrollView(frame: .zero)
    let scrollContentStackView = UIStackView(frame: .zero)

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
//        L.d("[test]sub", AWSMobileClient.default().userSub!)
        setNavigationItemRightMenu()
        view.backgroundColor = .white
        
        contentView.axis = .vertical
        contentView.alignment = .fill
        contentView.spacing = 0
        contentView.distribution = .fill
        
        view.addSubview(contentView)
        contentView.autoPinEdgesToSuperview()
        
        // MARK: - Name View
        contentView.addArrangedSubview(userNameView)
        userNameView.autoLayoutHeight(100)
        
        let tempView = UIView(frame: .zero)
        tempView.backgroundColor = .sesame2Green
        contentView.addArrangedSubview(tempView)
        tempView.addSubview(scrollView)

        scrollContentStackView.axis = .vertical
        scrollContentStackView.alignment = .fill
        scrollContentStackView.spacing = 0
        scrollContentStackView.distribution = .fill

        // MARK: - Scroll View
        scrollView.addSubview(scrollContentStackView)
        UIView.autoLayoutStackView(scrollContentStackView, inScrollView: scrollView)
        scrollView.backgroundColor = .white
        AWSMobileClient.default().addUserStateListener(self) { state, _ in
            executeOnMainThread {
                self.userState = state
                self.userStateView.text = self.userState.rawValue
            }
        }
        
        // MARK: - 添加下拉刷新控件：更新昵称
        let refreshControl: UIRefreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadNickName), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        
        arrangeSubview()
    }

    func arrangeSubview() {
        for subview in scrollContentStackView.arrangedSubviews {
            subview.removeFromSuperview()
            scrollContentStackView.removeArrangedSubview(subview)
        }
        userState = AWSMobileClient.default().currentUserState
        
        self.getNickName()
        
        if userState == .signedIn {
            let email = CHUserAPIManager.shared.getEmail { result in
                if case let .success(email) = result {
                    executeOnMainThread {
                        self.userNameView.historyTagHintLabel.text = email ?? ""
                    }
                } else if case let .failure(error) = result {
                    executeOnMainThread {
                        self.view.makeToast(error.errorDescription())
                    }
                }
            }
            
            executeOnMainThread {
                self.userNameView.historyTagHintLabel.text = email
            }
            userNameView.qrCodeImageView.isHidden = false
        } else {
            userNameView.historyTagHintLabel.text = "co.candyhouse.sesame2.Email".localized
            userNameView.qrCodeImageView.isHidden = true
        }
        
        let notifyView = CHUIViewGenerator.arrow { [weak self] _,_ in
            let token: String = UserDefaults.standard.string(forKey: "devicePushToken") ?? ""
            let web = CHWebViewController.instanceWithScene("device-notify", extInfo: [
                "pushToken": token
            ])
            self?.navigationController?.pushViewController(web, animated: true)
        }
        notifyView.title = "co.candyhouse.sesame2.enableNotification".localized
        scrollContentStackView.addArrangedSubview(notifyView)
        
        
        // MARK: - Padding
        let screenSize = UIScreen.main.bounds
        let screenHeight = screenSize.height
        let navBarHeight = UIApplication.shared.statusBarFrame.size.height +
        (navigationController?.navigationBar.frame.height ?? 0.0)
        let tabBarHeight = tabBarController?.tabBar.frame.size.height ?? 49
        let paddingView = UIView(frame: .zero)
        let nameLabelUserStateVersionLabelHeight: CGFloat = 160.0
        paddingView.autoLayoutHeight(screenHeight - navBarHeight - tabBarHeight - nameLabelUserStateVersionLabelHeight)
        paddingView.backgroundColor = .white
        scrollContentStackView.addArrangedSubview(paddingView)
        
        // MARK: - User state
        scrollContentStackView.addArrangedSubview(userStateView)
        userStateView.textAlignment = .center
        userStateView.translatesAutoresizingMaskIntoConstraints = false
        userStateView.font = UIFont(name: "TrebuchetMS", size: 15)
        userStateView.autoLayoutHeight(30)
        userStateView.textColor = UIColor.placeHolderColor
        userStateView.text = AWSMobileClient.default().currentUserState.rawValue
        userStateView.sizeToFit()
        
        // MARK: - Version Tag
        let versionLabelWithLink = VersionLabel(
            downloadURL: "https://testflight.apple.com/join/Rok4GOFD"
        )
        scrollContentStackView.addArrangedSubview(versionLabelWithLink)
        scrollContentStackView.addArrangedSubview(CHUISeperatorView(style: .group,separatorViewBackgroundColor: .white))
        
        // MARK: - 登出
        if userState == .signedIn {
            let title = "co.candyhouse.sesame2.LogOut".localized
            
            logOutView = CHUICallToActionView { [unowned self] sender,_ in
                guard let button = sender as? UIButton else {
                    L.d("Error: logOutView sender is not a UIButton")
                    return
                }
                self.performLogout(logOutTitle: title, sender: button)
            }
            logOutView!.title = title
            logOutView?.backgroundColor = .sesame2Gray
            scrollContentStackView.addArrangedSubview(logOutView!)
            scrollContentStackView.addArrangedSubview(CHUISeperatorView(style: .thick,separatorViewBackgroundColor: .white))
            
            // 與刪除按鈕的距離
            let spacerView = UIView()
            scrollContentStackView.addArrangedSubview(spacerView)
            NSLayoutConstraint.activate([
                spacerView.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
        }
        
        // MARK: - 刪除帳號
        if userState == .signedIn {
            let title = "co.candyhouse.sesame2.AccountDeletion".localized
            
            delAccountView = CHUICallToActionView { [unowned self] sender,_ in
                guard let button = sender as? UIButton else {
                    L.d("Error: delAccountView sender is not a UIButton")
                    return
                }
                self.performLogout(logOutTitle: title, sender: button)
            }
            delAccountView!.title = title
            delAccountView?.backgroundColor = .sesame2Gray
            scrollContentStackView.addArrangedSubview(delAccountView!)
        }
    }
    
    // MARK: - User events
    @objc func changeNameTapped() {
        userState = AWSMobileClient.default().currentUserState
        var oldValue = ""
        var title = ""
        
        if userState == .signedIn {
            oldValue = userNameView.titleLabel.text ?? ""
            title = "co.candyhouse.sesame2.FullName".localized
        } else {
            oldValue = UserDefaults.standard.string(forKey: "email") ?? ""
            title = "co.candyhouse.sesame2.Email".localized
        }

        if self.userState == .signedIn {
            ChangeValueDialog.show(oldValue,
                                   title: title) { newValue in
                
                guard self.userNameView.titleLabel.text != newValue else {
                    return
                }
                
                CHUserAPIManager.shared.updateNickname(newValue) { result in
                    if case let .success(nickName) = result {
                        executeOnMainThread {
                            self.userNameView.titleLabel.text = nickName
                            WatchKitFileTransfer.shared.transferKeysToWatch()
                        }
                    } else if case let .failure(error) = result {
                        executeOnMainThread {
                            self.view.makeToast(error.errorDescription())
                        }
                    }
                }
            }
        } else {
            self.navigateLoginViewController()
        }
    }
    
    @objc func shareUser() {
        if userState == .signedIn {
            let qrCodeViewController = QRCodeViewController.instanceWithUser()
            self.navigationController?.pushViewController(qrCodeViewController, animated: true)
        }
    }
    
    func navigateLoginViewController() {
        let loginViewController = SignUpViewController.instance { isLoggedIn in
            if isLoggedIn {
//                CHUserAPIManager.shared.setCredentialsProvider(AWSMobileClient.default())
//                CHFudonsanAPIManager.shared.setCredentialsProvider(AWSMobileClient.default())
                CHUserAPIManager.shared.getNickname { result in
                    // Set History tag
                    if case let .success(nickname) = result {
                        if nickname == nil {
                            CHUserAPIManager.shared.getEmail { getEmailResult in
                                if case let .success(email) = getEmailResult {
                                    let emailId = String(email!.split(separator: "@").first!)
                                    CHUserAPIManager.shared.updateNickname(emailId) { updateResult in
                                        executeOnMainThread {
                                            self.arrangeSubview()
                                        }
                                    }
                                }
                            }
                        } else {
                            executeOnMainThread {
                                self.arrangeSubview()
                            }
                        }
                        CHUserAPIManager.shared.getSubId { subId in
                            if let subId = subId, !subId.isEmpty {
                                let ss5history = CHUserAPIManager.shared.formatSubuuid(subId)
                                Sesame2Store.shared.setSubUuid(ss5history)
                            }
                        }
                    } else {
                        executeOnMainThread {
                            self.arrangeSubview()
                        }
                    }
                }
            }
        }
        navigationController?.pushViewController(loginViewController, animated: true)
    }
    
    @objc func reloadNickName() {
        self.getNickName()
        scrollView.refreshControl?.endRefreshing()
    }
    
    // MARK: 刷新昵称
    func getNickName() {
        if userState == .signedIn {
            let nickname = CHUserAPIManager.shared.getNickname ({ result in
                if case let .success(nickName) = result {
                    executeOnMainThread {
                        self.userNameView.titleLabel.text = nickName
                    }
                } else if case let .failure(error) = result {
                    executeOnMainThread {
                        self.view.makeToast(error.errorDescription())
                    }
                }
            },isCachingEnabled: false)
            
            executeOnMainThread {
                self.userNameView.titleLabel.text = nickname
            }
        } else {
            self.userNameView.titleLabel.text = "co.candyhouse.sesame2.LogIn".localized + "/" + "co.candyhouse.sesame2.SignUp".localized
        }
    }
    
    func performLogout(logOutTitle: String, sender: UIButton) {
        let preferredStyle: UIAlertController.Style = .actionSheet
        let alertController = UIAlertController(title: logOutTitle, message: nil, preferredStyle: preferredStyle)

        let signOut = UIAlertAction(title: "co.candyhouse.sesame2.OK".localized, style: .destructive) { _ in
            // MARK: - Log out
            CHUserAPIManager.shared.signOut {
                CHDeviceManager.shared.setHistoryTag()
                Sesame2Store.shared.setSubUuid(Data())
                CHDeviceWrapperManager.shared.clear()
                executeOnMainThread {
                    self.arrangeSubview()
                }
            }
        }

        let cancel = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil)
        alertController.addAction(signOut)
        alertController.addAction(cancel)

        alertController.popoverPresentationController?.sourceView = sender

        present(alertController, animated: true)
    }
    
}
