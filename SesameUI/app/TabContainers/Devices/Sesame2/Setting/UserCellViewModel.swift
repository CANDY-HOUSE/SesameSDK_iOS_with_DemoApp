//
//  UserCellViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

public final class UserCellViewModel: ViewModel {
    public var statusUpdated: ViewStatusHandler?
    
    let avatar: String
    let isOwnerKingHidden: Bool
    
    public init(avatar: String, isOwnerKingHidden: Bool) {
        self.avatar = avatar
        self.isOwnerKingHidden = isOwnerKingHidden
    }
}
