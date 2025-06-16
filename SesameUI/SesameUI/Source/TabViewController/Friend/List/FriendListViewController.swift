//
//  FriendListViewController.swift
//  SesameUI
//
//  Created by tse on 2023/05/27.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import AWSMobileClientXCF
import SesameSDK

extension FriendListViewController {
    static func instance(popupMenu: Bool = true, selectHandler: ((CHUser?, UIView?)->Void)? = nil) -> FriendListViewController {
        let vc = FriendListViewController(nibName: nil, bundle: nil)
        vc.dismissHandler = selectHandler
        UINavigationController().pushViewController(vc, animated: false)
        return vc
    }
}

class FriendListViewController: CHBaseViewController {
    public private(set) var tableView: UITableView!
    public private(set) var tableViewProxy: CHTableViewProxy!
    public private(set) var dismissHandler: ((CHUser?, UIView?)->Void)? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if dismissHandler == nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: "icons_outlined_addoutline"), style: .done,target: self,action: #selector(handleRightBarButtonTapped(_:)))
        }
        AWSMobileClient.default().addUserStateListener(self) { [weak self] state, dic in
            guard let self = self else { return }
            executeOnMainThread {
                self.getFriends()
            }
        }
        configureTable()
    }
    
    func configureTable() {
        tableViewProxy = CHTableViewProxy(superView: self.view, selectHandler: { [unowned self] cellDescriptor, _ in
            if let friend = cellDescriptor.rawValue as? CHUser {
                if self.dismissHandler != nil {
                    self.dismissHandler!(friend, self.view)
                    return
                }
                self.navigateToFriendKeyVC(friend)
            }
        } ,emptyPlaceholder: "co.candyhouse.sesame2.NoContacts".localized)
        tableView = tableViewProxy.tableView
        tableViewProxy.configureTableHeader { [unowned self] in
            self.getFriends()
        } _: { [unowned self] in
            self.getFriends(isLoadMore: true)
        }
        self.getFriends()
    }
    
    func getFriends(isLoadMore: Bool = false) {
        guard tableViewProxy != nil else { return }
        guard AWSMobileClient.default().currentUserState == .signedIn else {
            tableViewProxy.handleSuccessfulDataSource([], isLoadMore: isLoadMore)
            return
        }
        //        L.d("[frined][page][\(self.friends.last?.subId.uuidString.lowercased())]")
        CHUserAPIManager.shared.getFriends(isLoadMore ? (tableViewProxy.dataSource.last?.rawValue as! CHUser).subId.uuidString.lowercased() : nil) { [weak self] result in
            executeOnMainThread {
                guard let self = self else { return }
                switch result {
                case .success(let friends):
                    //                    L.d("[friendList] getFriends <=", friends.data)
                    //                    L.d("[frined][data]",friends.data)
                    self.tableViewProxy.handleSuccessfulDataSource(friends.data, isLoadMore: isLoadMore)
                case .failure(let error):
                    //                    L.d("[friendList] getFriends <=", error)
                    self.tableViewProxy.handleFailedDataSource(error)
                }
            }
        }
    }
    
    func navigateToFriendKeyVC(_ friend: CHUser) {
        let friendKeyListViewController = FriendKeyListViewController.instance(friend) { [weak self] isFriendDeleted in
            guard let self = self else { return }
            if isFriendDeleted {
                executeOnMainThread {
                    self.tableViewProxy.dataSource.removeAll { ($0.rawValue as! CHUser).subId == friend.subId }
                    self.tableViewProxy.reload()
                }
            }
        }
        navigationController?.pushViewController(friendKeyListViewController, animated: true)
    }
}
