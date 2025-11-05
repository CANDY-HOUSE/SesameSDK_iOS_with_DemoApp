//
//  Request.swift
//  Sesame2SDK
//
//  Created by tse on 2020/3/17.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

#if os(iOS)
import AWSCore
import AWSAPIGateway
#elseif os(watchOS)
import WatchKit
#endif
import Foundation

extension CHAccountManager {
    func API(request: CHAPICallObject,
                         handler: @escaping (Result<Data?, Error>) -> Void) {

        let awsTask = apiGatewayClient.invoke(request.toAWSGatewayRequest())
        awsTask.continueWith( block: { (task: AWSTask) -> Any? in
            
            if let error = task.error {
                handler(.failure(error))
                return nil
            }
            
            guard let response = task.result else {
                handler(.success(nil))
                return nil
            }
            
            switch response.statusCode {
            case 200, 204:
                handler(.success(response.responseData))
            case 404, 401, 403, 409, 502:
                guard let _ = response.responseData else {
                    let error = NSError(domain: "Sesame2SDK", code: response.statusCode, userInfo: ["message": response.rawResponse])
                    handler(.failure(error))
                    return nil
                }
                let error = self.errorFromResponse(response)
                handler(.failure(error))
            default:
                guard let _ = response.responseData else {
                    let error = NSError(domain: "Sesame2SDK", code: response.statusCode, userInfo: ["message": response.rawResponse])
                    handler(.failure(error))
                    return nil
                }
                let error = self.errorFromResponse(response)
                handler(.failure(error))
            }
            return nil
        })

    }

    private func errorFromResponse(_ response: AWSAPIGatewayResponse) -> Error {
        do {
            let errorFromServer = try JSONDecoder().decode(CHServerError.self, from: response.responseData!)
            return NSError(domain: "Sesame2SDK", code: response.statusCode, userInfo: ["message": errorFromServer.message])
        } catch {
            return NSError(domain: "Sesame2SDK", code: response.statusCode, userInfo: ["message": response.rawResponse])
        }
    }
    
    /// 订阅 SNS 主题
    /// - Parameters:
    ///   - topicName: 主题名称
    ///   - pushToken: APNs token (iOS) 或 FCM token (Android)
    ///   - appIdentifyId: 设备唯一标识
    ///   - platform: 平台类型 (ios, ios_sandbox, android)
    ///   - completion: 完成回调
    public func subscribeToSNSTopic(
        topicName: String,
        pushToken: String,
        appIdentifyId: String,
        platform: String,
        completion: @escaping (Bool) -> Void
    ) {
        let parameters: [String: Any] = [
            "action": "subscribeToTopic",
            "topicName": topicName,
            "pushToken": pushToken,
            "appIdentifyId": appIdentifyId,
            "platform": platform
        ]
        
        let payload = try! JSONSerialization.data(withJSONObject: parameters)
        
        self.API(request: .init(.post, "/device/v1/subscribe", payload)) { response in
            switch response {
            case .success(let data):
                if let jsonObj = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any],
                   let bodyString = jsonObj["body"] as? String,
                   bodyString.contains("\"success\":true") {
                    completion(true)
                } else {
                    completion(false)
                }
            case .failure(let error):
                L.d("sf", "Subscribe error: \(error)")
                completion(false)
            }
        }
    }
}

public class CHServerError: Codable {
    public var message: String = ""
    enum CodingKeys : String, CodingKey {
        case message
    }
}


extension CHAccountManager {
    public func publicAPI(request: PublicAPICallObject,
                         handler: @escaping (Result<Data?, Error>) -> Void) {
        // 将公开的请求转换为内部请求
        let internalRequest = request.toCHAPICallObject()
        self.API(request: internalRequest, handler: handler)
    }
    
    public func subscribeTopic(topic: String, result: @escaping CHResult<Data>) {
        L.d("CHHub3Device", "[hub3] subscribeTopic \(topic)")
        CHIoTManager.shared.subscribeTopic(topic) {data in
            guard let data = data as? Data else {
                L.d("CHHub3Device", "[hub3] subscribeTopic 格式錯誤")
                return
            }
            result(.success(CHResultStateNetworks(input: Data(data))))
        }
    }
    
   public func unsubscribeTopic(topic: String) {
//        let topic = "hub3/\(deviceId.uuidString.uppercased())/ir/learned/data"
        CHIoTManager.shared.unsubscribeTopic(topic)
    }
}
