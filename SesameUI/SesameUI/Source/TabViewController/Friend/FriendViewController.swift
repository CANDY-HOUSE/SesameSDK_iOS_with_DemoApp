//
//  FriendListViewController.swift
//  SesameUI
//
//  Created by tse on 2023/05/27.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

extension FriendViewController {
    static func instance() -> FriendViewController {
        let vc = FriendViewController(nibName: nil, bundle: nil)
        UINavigationController().pushViewController(vc, animated: false)
        return vc
    }
    static func instanceWithFriendAdd() -> FriendViewController {
        let vc = FriendViewController(nibName: nil, bundle: nil)
        vc.hidesBottomBarWhenPushed = true
        vc.addFriend = true
        UINavigationController().pushViewController(vc, animated: false)
        return vc
    }
}

class FriendViewController: CHWebHostViewController {
    private var addFriend: Bool = false
    private var userState: UserState = .unknown

    override var webScene: String? { addFriend ? "contact-add" : "contacts" }
    override var reloadAndPopNotifyName: String? { "FriendChanged" }
    override var showsNavigationRightMenu: Bool { !addFriend }

    override func didFinishInitialSetup() {
        if !addFriend {
            monitorAWSMobileClientUserState()
        }
    }

    private func monitorAWSMobileClientUserState() {
        let statusChangeHandler: (_ state: UserState) -> Void = { [weak self] state in
            if (state == .signedIn && self?.userState == .signedOut) ||
               (state == .signedOut && self?.userState == .signedIn) {
                self?.webView?.refresh()
            }
            self?.userState = state
        }
        CHAWSManager.addUserStateListener(self) { state in
            executeOnMainThread {
                statusChangeHandler(state)
            }
        }
        userState = CHAWSManager.currentUserState
    }
}
