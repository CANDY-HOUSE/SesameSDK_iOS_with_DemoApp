//
//  FindFriendHandler.swift
//  SesameUI
//
//  Created by eddy on 2024/5/16.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import AWSCognitoIdentityProvider
import AWSMobileClientXCF

protocol UserFinder: AnyObject {
    // 添加好友
    func addFriendByEmail(_ email: String, completion: @escaping (CHUser?, Error?) -> Void)
    
    // 根據郵箱地址查找用戶
    func findUserFromCognitoUserPool(_ email: String, completion: @escaping (AWSCognitoIdentityProviderUserType?, Error?) -> Void)
}


final class FindFriendHandler: UserFinder {
    
    static let shared = FindFriendHandler()
    
    private let serviceConf = AWSServiceConfiguration(region: .APNortheast1, credentialsProvider: AWSMobileClient.default())
    private let CognitoIdentityKey = "CHCognitoListUser"
    
    private var userPoolId: String? {
        let awsInfo = AWSInfo.default().rootInfoDictionary
        if let cognitoUserPool = awsInfo["CognitoUserPool"] as? [String: Any],
           let userPoolDefault = cognitoUserPool["Default"] as? [String: Any],
           let poolId = userPoolDefault["PoolId"] as? String {
            return poolId
        } else {
            return nil
        }
    }
    
    init() {
        AWSCognitoIdentityProvider.register(with: serviceConf!, forKey: CognitoIdentityKey)
    }
    
    deinit {
        AWSCognitoIdentityProvider.remove(forKey: CognitoIdentityKey)
    }
    
    func addFriendByEmail(_ email: String, completion: @escaping (CHUser?, Error?) -> Void) {
        findUserFromCognitoUserPool(email) { (resp, err) in
            if let error = err {
                completion(nil ,error)
            } else {
                if let payload = resp, let user = payload.toCHUser() {
                    CHUserAPIManager.shared.postFriend(user.subId.uuidString.lowercased()) { result in
                        completion(user, nil)
                    }
                } else {
                    completion(nil, NSError.getUserInfoError)
                }
            }
        }
    }
    
    func findUserFromCognitoUserPool(_ email: String, completion: @escaping (AWSCognitoIdentityProviderUserType?, Error?) -> Void) {
        let req = AWSCognitoIdentityProviderListUsersRequest()
        req?.userPoolId = userPoolId
        req?.filter = "email = \"\(email)\""
        AWSCognitoIdentityProvider(forKey: CognitoIdentityKey).listUsers(req!) { resp, err in
            if let error = err {
                completion(nil, error)
            } else {
                completion(resp?.users?.first, nil)
            }
        }
    }
}

extension AWSCognitoIdentityProviderUserType {
    func toCHUser() -> CHUser? {
        guard let attributes = attributes else { return nil }
        var subId: UUID?
        var nickname: String?
        var email: String?
        var keyLevel: Int?
        var gtag: String?
        
        for attribute in attributes {
            guard let name = attribute.name, let value = attribute.value else {
                continue
            }
            switch name {
            case "sub":
                subId = UUID(uuidString: value.lowercased())
            case "nickname":
                nickname = value
            case "email":
                email = value
            default: break
            }
        }
        return CHUser(subId: subId!, nickname: nickname, email: email!, keyLevel: nil, gtag: nil)
    }
}
