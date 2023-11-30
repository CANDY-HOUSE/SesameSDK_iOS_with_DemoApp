//
//  Request.swift
//  Sesame2SDK
//
//  Created by tse on 2020/3/17.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension CHAccountManager {
    func API(request: CHAPICallObject,
             handler: @escaping (Result<Data?, Error>) -> Void) {}
    }

public class CHServerError: Codable {
    public var message: String = ""
    enum CodingKeys : String, CodingKey {
        case message
    }
}
