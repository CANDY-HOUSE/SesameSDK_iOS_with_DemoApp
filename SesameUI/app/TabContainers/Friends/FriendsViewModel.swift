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
    
    public private(set) var emptyMessage = "No Contacts".localStr
    private(set) var actonTitle = "DeleteFriend".localStr
    private(set) var pullToRefreshTitle = "Pull to refresh".localStr
    
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
//        let uuid = friends[row].id.uuidString
//        CHAccountManager.shared.unfriend(fdId: uuid) { result in
//            switch result {
//            case .success(_):
//                self.friends.remove(at: row)
//                self.statusUpdated?(.finished(.success("")))
//            case .failure(let error):
//                self.statusUpdated?(.finished(.failure(error)))
//            }
//        }
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
