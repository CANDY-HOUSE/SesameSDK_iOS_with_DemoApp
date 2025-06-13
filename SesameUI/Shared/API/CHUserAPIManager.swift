//
//  CHUserAPIManager.swift
//  SesameUI
//  Created by YuHan Hsiao on 2021/08/11.
//  Copyright © 2021 CandyHouse. All rights reserved.
//
/**
 API Gateway ID : 0dkzum4jzg
 API Gateway desc : " app需要登入才能用的API " 
 */

import Foundation
import AWSCore
import AWSAPIGateway
import AWSMobileClientXCF
import SesameSDK

#if DEBUG
private let awsApiGatewayBaseUrl = "https://0dkzum4jzg.execute-api.ap-northeast-1.amazonaws.com/dev"
#else
private let awsApiGatewayBaseUrl = "https://0dkzum4jzg.execute-api.ap-northeast-1.amazonaws.com/prod"
#endif

/// 用戶登出登入變化事件介面
protocol CHUserManagerSignInDelegate: AnyObject {
    func signInCompleteHandler(_ result: Result<NSNull, Error>)
    func signInStatusDidChanged(_ status: SignInState)
}

/// Sesame 登入後調用 API
/// 管理用戶註冊，登入，登出，設定暱稱，取得用戶訊息。
/// 新增/更新/取得/刪除 用戶網路鑰匙
/// 新增移除好友，給好友鑰匙，刪好友鑰匙
class CHUserAPIManager: CHAPIManagerType {
    static let shared = CHUserAPIManager()
    let apiClient = AWSAPIGatewayClient()
    var apiURL: String = awsApiGatewayBaseUrl
    weak var delegate: CHUserManagerSignInDelegate?
    private(set) var fudosanAccessLevel = [String]()
    
    var subId: String?
    var nickName: String?
    var email: String?
}

extension CHUserAPIManager {
    /// 上傳手機GPS
    func postCHDeviceIno(_ deviceInfo: CHDeviceInfo, _ result: @escaping CHResult<Any>) {
        let jsonData = try! JSONEncoder().encode(deviceInfo)
//        L.d("[CHUserAPIManager][postCHDeviceIno] <-")
        API(request: .init(.post, "/device/infor", jsonData)) { uploadResult in
            switch uploadResult {
            case .success(_):
                result(.success(.init(input: "")))
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
}
