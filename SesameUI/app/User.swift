//
//  User.swift
//  sesame-sdk-test-app
//
//  Created by Wayne Hsiao on 2020/5/3.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

public struct User: Codable {
    
    enum CodingKeys: String, CodingKey {
        case familyName = "family_name"
        case givenName = "given_name"
        case emailVerified = "email_verified"
        case sub = "sub"
        case email = "email"
    }
    
    public var familyName: String
    public var givenName: String
    public var emailVerified: String
    public var sub: String
    public var email: String
    
    public init(familyName: String, givenName: String, emailVerified: String, sub: String, email: String) {
        self.familyName = familyName
        self.givenName = givenName
        self.emailVerified = emailVerified
        self.sub = sub
        self.email = email
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let familyName = try container.decode(String.self, forKey: .familyName)
        let givenName = try container.decode(String.self, forKey: .givenName)
        let emailVerified = try container.decode(String.self, forKey: .emailVerified)
        let sub = try container.decode(String.self, forKey: .sub)
        let email = try container.decode(String.self, forKey: .email)
        
        self.init(familyName: familyName,
                  givenName: givenName,
                  emailVerified: emailVerified,
                  sub: sub,
                  email: email)
    }
}

public extension User {
    static func userFromAttributes(_ attributes: [String: String]) throws -> User {
        let jsonData = try JSONSerialization.data(withJSONObject: attributes, options: .prettyPrinted)
        let decoder = JSONDecoder()
        let user = try decoder.decode(User.self, from: jsonData)
        return user
    }
}
