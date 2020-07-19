//
//  DeleteFriendViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

//final class DeleteFriendViewModel: ViewModel {
//    private var currentFriends = [Friend]()
//
//    public var delegate: AddFriendViewModelDelegate?
//    public var statusUpdated: ViewStatusHandler?
//
//    private(set) var title = "Members".localStr
//    private(set) var deleteFriendActionTitle = "Delete the Member".localStr
//
//    var numberOfRows: Int {
//        currentFriends.count
//    }
//
//    func friendCellViewModelForRow(_ row: Int) -> FriendCellModel {
//        FriendCellModel(friend: currentFriends[row])
//    }
//
//    func deleteFriendActionForRow(_ row: Int) {

//        let member = members[row]
//        self.sesame!.revokeKey(member.id) { (result) in
//            DispatchQueue.main.async {
//                ViewHelper.hideLoadingView(view: self.view)
//            }
//            switch result {
//            case .success(_):
//                self.sesame?.getDeviceMembers() { result in
//                    DispatchQueue.main.async {
//                        switch result {
//                        case .success(let users):
//                            self.memberList = users.data
//                            self.friendTable.reloadData()
//                        case .failure(let error):
//                            L.d(ErrorMessage.descriptionFromError(error: error))
//                            self.navigationController?.popToRootViewController(animated: true)
//                        }
//                    }
//                }
//            case .failure(let error):
//                L.d(ErrorMessage.descriptionFromError(error: error))
//            }
//        }
//    }
//}
