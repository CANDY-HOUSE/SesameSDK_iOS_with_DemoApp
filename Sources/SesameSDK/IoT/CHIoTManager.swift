//
//  CHIotManager.swift
//  SesameSDK
//
//  Created by tse on 2020/8/14.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

#if os(iOS)
import AWSIoT
import AWSCognitoIdentityProvider
import Foundation

private let AWSManagerKey = "IoTDataManager"
extension AWSIoTMQTTStatus {
    func description() -> String {
        switch self {
        case .unknown:
            return "unknown"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .disconnected:
            return "disconnected"
        case .connectionRefused:
            return "connectionRefused"
        case .connectionError:
            return "connectionError"
        case .protocolError:
            return "protocolError"
        @unknown default:
            return "default"
        }
    }
}

extension AWSServiceConfiguration {
    static var chIoTConfiguration: AWSServiceConfiguration = {
        let cognitoCredentialsProvider = AWSCognitoCredentialsProvider(regionType: CHConfiguration.shared.region(),
                                                                       identityPoolId: CHConfiguration.shared.clientId)
        let anonymous = AWSAnonymousCredentialsProvider()
        let endpoint = AWSEndpoint(urlString: AWSConfigManager.config.iotEndpoint)
        let serviceConfiguration = AWSServiceConfiguration(region: .APNortheast1,
                                                           endpoint: endpoint,
                                                           credentialsProvider: cognitoCredentialsProvider)!
        return serviceConfiguration
    }()
}

extension CHDevice {
    func makeIoTStatusToDisconnect() {
        guard self is CHWifiModule2 else { return }
        self.mechStatus = CHWifiModule2NetworkStatus(isAPWork: false,
                                                     isNetwork: false,
                                                     isIoTWork: false,
                                                     isBindingAPWork: false,
                                                     isConnectingNetwork: false,
                                                     isConnectingIoT: false)
    }
}

final class CHIoTManager {
    static let shared = CHIoTManager()
    lazy var awsIoTDataManager: AWSIoTDataManager = {  return AWSIoTDataManager(forKey: AWSManagerKey) }()
    lazy var awsIoTData: AWSIoTData = { return AWSIoTData(forKey: AWSManagerKey) }()

    var connectionStatus: AWSIoTMQTTStatus = .unknown
    
    private init() {
//        L.d("[iot]CHIoTManager,init =>")
        let mqttConfig = AWSIoTMQTTConfiguration(keepAliveTimeInterval: 60.0,
                                                 baseReconnectTimeInterval: 1.0,
                                                 minimumConnectionTimeInterval: 1.0,
                                                 maximumReconnectTimeInterval: 1.0,
                                                 runLoop: RunLoop.current,
                                                 runLoopMode: RunLoop.Mode.default.rawValue,
                                                 autoResubscribe: false,
                                                 lastWillAndTestament: AWSIoTMQTTLastWillAndTestament())
        AWSIoTDataManager.register(with: AWSServiceConfiguration.chIoTConfiguration,
                                   with: mqttConfig,
                                   forKey: AWSManagerKey)
        AWSIoTData.register(with: AWSServiceConfiguration.chIoTConfiguration,
                            forKey: AWSManagerKey)
        let _ = NetworkReachabilityHelper.shared
    }
    
    func reconnect() {
        L.d("[iot]CHIoTManager,reconnect =>")
        self.awsIoTDataManager
            .connectUsingWebSocket(withClientId: UUID().uuidString,
                                   cleanSession: true,
                                   statusCallback: self.statusCallback)
    }
    
    func statusCallback(_ status: AWSIoTMQTTStatus) {
//        L.d("[iot]CHIoTManager, MQTTStatus=>", status.description())
        // Disconnected
        if status != connectionStatus, connectionStatus == .connected {
            CHDeviceManager.shared.getCHDevices { getResult in
                if case let .success(devices) = getResult {
                    for device in devices.data {
                        device.deviceShadowStatus = nil
                        device.makeIoTStatusToDisconnect()
                    }
                }
            }
            // Connected
        } else if status != connectionStatus, status == .connected {
            CHDeviceManager.shared.getCHDevices { getResult in
                if case let .success(devices) = getResult {
                    for device in devices.data {
                        if let wifiModule2 = device as? CHWifiModule2 {
                            self.unsubscribeWifiModule2Shadow(wifiModule2)
                        } else {
                            self.unsubscribeCHDeviceShadow(device)
                        }
                        (device as? CHDeviceUtil)?.goIOT()
                    }
                }
            }
        }
        connectionStatus = status
    }

    // MARK: - Get wm2 shadow
    func getWifiModule2Shadow(_ wifiModule2: CHWifiModule2, onResponse: (CHResult<WifiModuleShadow>)? = nil) {
        let request = AWSIoTDataGetThingShadowRequest()!
        request.thingName = "wm2"
        request.shadowName = "\(wifiModule2.deviceId.uuidString.split(separator: "-").last!)"
        let parserGet: WifiModuleShadow.Type? = wifiModule2.productModel == .hub3 ? nil : WifiModule2Shadow.self
        if let parser = parserGet {
            awsIoTData.getThingShadow(request) { response, error in
                if let payload = response?.payload as? Data {
                    let shadow = parser.fromData(payload)
                    onResponse?(.success(.init(input: shadow)))
                } else if let error = error {
                    onResponse?(.failure(error))
                } else {
                    onResponse?(.failure(NSError.noDataError))
                }
            }
        }
    }

    // MARK: - Subscribe wm2 shadow
    func subscribeWifiModule2Shadow(_ wifiModule2: CHWifiModule2,
                                    onResponse: @escaping (CHResult<WifiModuleShadow>)) {
        //        wifiModule2.iotCustomVerification { verifyResult in
        //            if case .success(_) = verifyResult {
        let shadowName = wifiModule2.deviceId.uuidString.split(separator: "-").last!
        self.awsIoTDataManager
            .subscribe(toTopic: "$aws/things/wm2/shadow/name/\(shadowName)/update/accepted",
                       qoS: .messageDeliveryAttemptedAtMostOnce) { data in
                let parser: WifiModuleShadow.Type = wifiModule2.productModel == .hub3 ? Hub3Shadow.self : WifiModule2Shadow.self
                let shadow = parser.fromData(data)
                onResponse(.success(.init(input: shadow)))
            }
        self.getWifiModule2Shadow(wifiModule2, onResponse: onResponse)
    }
    
    func subscribeTopic(_ topic: String, callback: @escaping (Data) -> Void) {
        self.awsIoTDataManager.subscribe(toTopic: topic, qoS: .messageDeliveryAttemptedAtMostOnce, messageCallback: callback)
    }
    
    func unsubscribeTopic(_ topic: String) {
        self.awsIoTDataManager.unsubscribeTopic(topic)
    }

    // MARK: - Unsubscribe WM2
    func unsubscribeWifiModule2Shadow(_ device: CHWifiModule2) {
        guard let uuid = device.deviceId?.uuidString else {
            return
        }
        let shadowName = uuid.split(separator: "-").last!
        awsIoTDataManager
            .unsubscribeTopic("$aws/things/wm2/shadow/name/\(shadowName)/update/accepted")
    }
    
    // MARK: - Subscribe Sesame2
    func subscribeCHDeviceShadow(_ device: CHDevice,
                                 onResponse: @escaping (CHResult<CHDeviceShadow>)) {
        func subscirbe() {
            L.d("[iot]subscirbeCHDeviceShadow =>",device.deviceId.uuidString)
            self.awsIoTDataManager
                .subscribe(toTopic: "$aws/things/sesame2/shadow/name/\(device.deviceId.uuidString)/update/accepted",
                           qoS: .messageDeliveryAttemptedAtMostOnce) { data in
//                    L.d("[iot]subscirbe data =>", data.toHexLog())
                    let shadow = CHDeviceShadow.fromData(data)
//                    L.d("[iot]subscirbe 影子 =>",shadow)
                    onResponse(.success(.init(input: shadow)))
                }

            let request = AWSIoTDataGetThingShadowRequest()!
            request.thingName = "sesame2"
            request.shadowName = device.deviceId.uuidString
            self.awsIoTData.getThingShadow(request) { response, error in
                guard let data = response?.payload as? Data else {
                    onResponse(.failure(NSError.noDataError))
                    return
                }
                let shadow = CHDeviceShadow.fromData(data)
                onResponse(.success(.init(input: shadow)))
            }
        }
        if awsIoTDataManager.getConnectionStatus() == .disconnected {
            reconnect()
            return
        }
        subscirbe()
    }

    // MARK: - Unsubscribe Sesame2
    func unsubscribeCHDeviceShadow(_ device: CHDevice) {
        guard let uuid = device.deviceId?.uuidString else {
            return
        }
        awsIoTDataManager
            .unsubscribeTopic("$aws/things/sesame2/shadow/name/\(uuid)/update/accepted")
    }
}///end

#endif

#if os(watchOS)
//import Foundation

final class CHIoTManager {
    static let shared = CHIoTManager()
    func getCHDeviceShadow(_ sesameLock: CHSesameLock, onResponse: (CHResult<CHDeviceShadow>)? = nil) {
        func getShadow() {
            CHAccountManager.shared.API(request: .init(.get, "/device/v1/sesame2/\(sesameLock.deviceId.uuidString)")) { apiResult in
                switch apiResult {
                case .success(let data):
                    L.d("⌚️ API getShadow ok",data)

                    if let shadow = CHDeviceShadow.fromRESTFulData(data!) {
                        onResponse?(.success(.init(input: shadow)))
                    }
                case .failure(let error):
                    L.d("⌚️ API error",error )
                    onResponse?(.failure(error))
                }
            }
        }
        getShadow()
    }
    
    func subscribeTopic(_ topic: String, callback: @escaping (Data) -> Void) { }
    func unsubscribeTopic(_ topic: String) { }
}

#endif

extension CHIoTManager { // [joi todo] 注意historyTag的設置機制，需優化(sesame2Store拿取historyTag)
    
    func sendCommandToWM2(_ command: SesameItemCode, _ historytag: Data, _ device: CHDevice, onResponse: @escaping (CHResult<CHEmpty>)) {
        var cmd = Int8()
        if command.rawValue <= Int8.max {
            cmd = Int8(command.rawValue)
        } else {
            cmd = Int8(bitPattern: command.rawValue)
        }
        send(cmd, historytag, device, onResponse: onResponse)
    }
    
    private func send(_ command: Int8, _ historytag: Data,  _ device: CHDevice, onResponse: @escaping (CHResult<CHEmpty>)) {
        guard let keyData = device.getKey() else {
            return
        }
        var timestamp: UInt32 = UInt32(Date().timeIntervalSince1970)
        let timestampData = Data(bytes: &timestamp,
                                 count: MemoryLayout.size(ofValue: timestamp))
        let randomTag = Data(timestampData.arrayOfBytes()[1...3])

        let keyCheck = CC.CMAC.AESCMAC(randomTag,
                                       key: keyData.secretKey.hexStringtoData())
        let hisTag: String = historytag.base64EncodedString()
        let parameter = [
            "cmd": command,
            "history": hisTag,
            "sign": keyCheck[0...3].toHexString()
        ] as [String : Any]
        
        CHAccountManager.shared.API(request: .init(.post, "/device/v1/iot/sesame2/\(device.deviceId.uuidString)",
                                                   parameter)) { apiResult in
            if case let .failure(error) = apiResult {
                onResponse(.failure(error))
            } else {
                onResponse(.success(.init(input: .init())))
            }
        }
    }
}
