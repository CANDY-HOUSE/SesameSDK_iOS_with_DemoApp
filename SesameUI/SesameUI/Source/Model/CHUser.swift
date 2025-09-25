//
//  CHUser.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/11/17.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

struct CHUser: Codable {
    let subId: UUID
    let nickname: String?
    let email: String
    let keyLevel: Int?
    var gtag: String?
    
    enum CodingKeys: String, CodingKey {
        case subId = "sub"
        case nickname
        case email
        case keyLevel
        case gtag
    }
    
    init(subId: UUID, nickname: String?, email: String, keyLevel: Int?, gtag: String?) {
        self.subId = subId
        self.nickname = nickname
        self.email = email
        self.keyLevel = keyLevel
        self.gtag = gtag
    }
}

extension CHUser {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.subId = try values.decode(UUID.self, forKey: .subId)
        self.nickname = try? values.decode(String.self, forKey: .nickname)
        self.email = try values.decode(String.self, forKey: .email)
        self.keyLevel = try? values.decode(Int.self, forKey: .keyLevel)
        self.gtag = try? values.decodeIfPresent(String.self, forKey: .gtag)
    }
}
