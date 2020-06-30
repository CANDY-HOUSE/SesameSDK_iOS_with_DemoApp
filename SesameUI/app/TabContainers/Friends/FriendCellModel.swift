//
//  FriendCellModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

final class FriendCellModel {
    var friend: Friend
    
    init(friend: Friend) {
        self.friend = friend
    }
    
    func name() -> String {
        friend.nickName
    }
    
    func headImage() -> String {
        friend.givenName
    }
}
