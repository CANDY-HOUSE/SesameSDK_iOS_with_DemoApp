//
//  AddFriendViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

//public protocol AddFriendViewModelDelegate {
//    func addNewFriendTapped()
//}
//
//public final class AddFriendViewModel: ViewModel {
//    
//    private var newFriends = [Friend]()
//    private var currentFriends: [SSMOperator]
//    
//    public var delegate: AddFriendViewModelDelegate?
//    
//    public var statusUpdated: ViewStatusHandler?
//    
//    public private(set) var title = "Contacts".localStr
//    public private(set) var refreshControlTitle = "Pull to refresh".localStr
//    public private(set) var rightButtonItemImage = "icons_filled_add-friends"
//    public private(set) var emptyMessage = "No Contacts".localStr
//    
//    public init(currentFriends: [SSMOperator]) {
//        self.currentFriends = currentFriends
//    }
//    
//    public func refresh() {
//        CHAccountManager.shared.myFriends(){ result in
//            switch result {
//            case .success(let friends):
//                self.newFriends = friends.data.sorted { $0.nickname! < $1.nickname! }
//                self.newFriends = self.newFriends.filter {
//                    let tmp = $0.id
//                    var idSame = true
//                    self.currentFriends.forEach {
//                        if $0.id == tmp { idSame = false }
//                    }
//                    return idSame
//                }
//                self.statusUpdated?(.received)
//            case .failure(let error):
//                self.statusUpdated?(.finished(.failure(error)))
//            }
//        }
//    }
//
//    public var numberOfRows: Int {
//        newFriends.count
//    }
//
//    func friendCellModelForRow(_ row: Int) -> FriendCellModel {
//        FriendCellModel(friend: newFriends[row])
//    }
//
//    func addFriendTitleForRow(_ row: Int) -> String? {
//        newFriends[row].nickName
//    }
//
//    var addFriendActionTitle: String {
//        "Add Member".localStr
//    }
//
//    func addFriendActionForRow(_ row: Int) {
//        // TODO: Implement add friend
//    }
//
//    func rightBarButtonTapped() {
//        delegate?.addNewFriendTapped()
//    }
//}
