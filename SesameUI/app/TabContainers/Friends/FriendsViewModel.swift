//
//  FriendsViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

public protocol FriendsViewModelDelegate {
    func scanViewTapped()
    func newSesameTapped()
}

public protocol Friend {
    var id: UUID { get }
    var familyName: String { get }
    var givenName: String { get }
    var nickName: String { get }
}

public final class FriendsViewModel: ViewModel {
    public var statusUpdated: ViewStatusHandler?
    private var friends = [Friend]()
    
    var delegate: FriendsViewModelDelegate?
    
    public private(set) var emptyMessage = "co.candyhouse.sesame-sdk-test-app.NoContacts".localized
    private(set) var actonTitle = "co.candyhouse.sesame-sdk-test-app.DeleteFriend".localized
    private(set) var pullToRefreshTitle = "co.candyhouse.sesame-sdk-test-app.PullToRefresh".localized
    
    public init() {

    }
    
    @objc
    func refresh() {
        friends = []
        statusUpdated?(.received)
    }
    
    public func rightbuttonItemImage() -> String {
        "icons_outlined_addoutline"
    }
    
    func friendCellModelForRow(_ row: Int) -> FriendCellModel {
        FriendCellModel(friend: friends[row])
    }
    
    public func numberOfRows() -> Int {
        friends.count
    }
    
    func tableViewDidSelectRowAt(_ row: Int) {
    }
    
    func titleForSelectedRow(_ row: Int) -> String? {
        friends[row].nickName
    }
    
    public func popUpMenuTappedOnItem(_ item: PopUpMenuItem) {
        switch item.type {
        case .addFriends:
            break
        case .addDevices:
            delegate?.newSesameTapped()
        case .receiveKey:
            delegate?.scanViewTapped()
        }
    }
}
