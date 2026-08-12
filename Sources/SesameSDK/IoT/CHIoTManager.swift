//
//  CHIotManager.swift
//  SesameSDK
//
//  Created by tse on 2020/8/14.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

#if os(iOS)
import AWSPluginsCore
import AwsIotDeviceSdkSwift

private enum CHIoTConnectionStatus: String {
    case unknown
    case connecting
    case connected
    case disconnected
    case connectionError
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

final class CHIoTManager: @unchecked Sendable {
    private struct TopicHandler {
        let subscriptionID: UUID
        var callback: (Data) -> Void
    }

    static let shared = CHIoTManager()
    private let lock = NSLock()
    private let clientCreationLock = NSLock()
    private let callbackQueue = DispatchQueue(label: "co.candyhouse.sesame.iot.callback")
    private let credentialsProvider: any CredentialsProviding
    private var client: Mqtt5Client?
    private var topicHandlers: [String: TopicHandler] = [:]
    private var connectionStatus: CHIoTConnectionStatus = .unknown
    private var clientStarted = false
    private var networkAvailable = true
    private var consecutiveWebSocketFailures = 0
    private var clientRecoveryRequested = false
    private var lastClientRecoveryAt: Date?
    private let clientRecoveryCooldown: TimeInterval = 60
    private let maximumSubscriptionAttempts = 3

    private init() {
        credentialsProvider = AWSAuthService().getCredentialsProvider()
        IotDeviceSdk.initialize()
        let reachability = NetworkReachabilityHelper.shared
        networkAvailable = reachability.currentState != .notReachable
        reachability.addListener(self) { [weak self] status in
            self?.networkStatusChanged(status)
        }
    }

    func reconnect() {
        L.d("[iot]CHIoTManager,reconnect =>")
        do {
            let mqttClient = try mqttClient()
            let shouldStart = lock.chIoTWithLock { () -> Bool in
                guard networkAvailable, !clientStarted else { return false }
                clientStarted = true
                return true
            }
            guard shouldStart else { return }
            enqueueStatus(.connecting)
            try mqttClient.start()
        } catch {
            lock.chIoTWithLock { clientStarted = false }
            enqueueStatus(.connectionError)
            L.d("[iot]CHIoTManager,reconnect error =>", error)
        }
    }

    private func networkStatusChanged(_ status: NetworkReachabilityStatus) {
        callbackQueue.async { [weak self] in
            guard let self else { return }
            switch status {
            case .notReachable:
                let shouldStop = self.lock.chIoTWithLock { () -> Bool in
                    guard self.networkAvailable else { return false }
                    self.networkAvailable = false
                    return true
                }
                guard shouldStop else { return }
                L.d("[iot] network unavailable, stopping MQTT")
                self.statusCallback(.disconnected)
                do {
                    try self.lock.chIoTWithLock { self.client }?.stop()
                } catch {
                    L.d("[iot] stop MQTT error =>", error)
                }
            case .reachable:
                let shouldReconnect = self.lock.chIoTWithLock { () -> Bool in
                    self.networkAvailable = true
                    return !self.clientStarted
                }
                L.d("[iot] network available")
                if shouldReconnect {
                    self.reconnect()
                }
            case .unknown:
                break
            }
        }
    }

    private func enqueueStatus(_ status: CHIoTConnectionStatus) {
        callbackQueue.async { [weak self] in
            self?.statusCallback(status)
        }
    }

    private func handleConnectionFailure(code: Int) {
        callbackQueue.async { [weak self] in
            guard let self else { return }
            self.statusCallback(.connectionError)

            let clientToStop = self.lock.chIoTWithLock { () -> Mqtt5Client? in
                guard code == 2065 else {
                    self.consecutiveWebSocketFailures = 0
                    return nil
                }
                self.consecutiveWebSocketFailures += 1
                guard self.consecutiveWebSocketFailures >= 3,
                      self.networkAvailable,
                      self.clientStarted,
                      !self.clientRecoveryRequested else {
                    return nil
                }
                let now = Date()
                if let lastRecoveryAt = self.lastClientRecoveryAt,
                   now.timeIntervalSince(lastRecoveryAt) < self.clientRecoveryCooldown {
                    return nil
                }
                self.consecutiveWebSocketFailures = 0
                self.clientRecoveryRequested = true
                self.lastClientRecoveryAt = now
                return self.client
            }
            guard let clientToStop else { return }

            L.d("[iot] rebuilding MQTT client after repeated WebSocket failures")
            do {
                try clientToStop.stop()
            } catch {
                self.lock.chIoTWithLock {
                    self.clientRecoveryRequested = false
                }
                L.d("[iot] stop failed MQTT client error =>", error)
            }
        }
    }

    private func statusCallback(_ status: CHIoTConnectionStatus) {
        let previousStatus = lock.chIoTWithLock { () -> CHIoTConnectionStatus in
            let previousStatus = connectionStatus
            connectionStatus = status
            if status == .connected {
                consecutiveWebSocketFailures = 0
            }
            return previousStatus
        }
        guard status != previousStatus else { return }
        L.d("[iot] MQTT status =>", previousStatus.rawValue, status.rawValue)
        if status != previousStatus, previousStatus == .connected {
            CHDeviceManager.shared.getCHDevices { getResult in
                if case let .success(devices) = getResult {
                    for device in devices.data {
                        device.deviceShadowStatus = nil
                        device.makeIoTStatusToDisconnect()
                    }
                }
            }
        } else if status != previousStatus, status == .connected {
            lock.chIoTWithLock { topicHandlers.removeAll() }
            CHDeviceManager.shared.getCHDevices { getResult in
                if case let .success(devices) = getResult {
                    for device in devices.data {
                        (device as? CHDeviceUtil)?.goIOT()
                    }
                }
            }
        }
        // 断线重连,快照由 App 启动时的 getKeysFromServer 提供,避免重复。
        if previousStatus == .disconnected && status == .connecting {
            CHAPIClient.shared.getCHUserKeys { _ in }
        }
    }

    // MARK: - Subscribe wm2 shadow
    func subscribeWifiModule2Shadow(_ wifiModule2: CHWifiModule2,
                                    onResponse: @escaping (CHResult<WifiModuleShadow>)) {
        let shadowName = wifiModule2.deviceId.uuidString.split(separator: "-").last!
        subscribeTopic("$aws/things/wm2/shadow/name/\(shadowName)/update/accepted") { data in
            let parser: WifiModuleShadow.Type = wifiModule2.productModel == .hub3 ? Hub3Shadow.self : WifiModule2Shadow.self
            onResponse(.success(.init(input: parser.fromData(data))))
        }
    }

    func subscribeTopic(_ topic: String, callback: @escaping (Data) -> Void) {
        let subscriptionID = UUID()
        let shouldSubscribe = lock.chIoTWithLock { () -> Bool in
            if var handler = topicHandlers[topic] {
                handler.callback = callback
                topicHandlers[topic] = handler
                return false
            }
            topicHandlers[topic] = TopicHandler(
                subscriptionID: subscriptionID,
                callback: callback
            )
            return true
        }
        guard shouldSubscribe else { return }
        Task {
            await subscribe(
                topic: topic,
                subscriptionID: subscriptionID
            )
        }
    }

    private func subscribe(topic: String, subscriptionID: UUID) async {
        for attempt in 1...maximumSubscriptionAttempts {
            let isCurrentSubscription = lock.chIoTWithLock {
                topicHandlers[topic]?.subscriptionID == subscriptionID
            }
            guard isCurrentSubscription else { return }

            do {
                let mqttClient = try mqttClient()
                let suback = try await mqttClient.subscribe(
                    subscribePacket: SubscribePacket(topicFilter: topic, qos: .atMostOnce)
                )
                if suback.reasonCodes.contains(where: { $0.rawValue >= 128 }) {
                    removeTopicHandler(topic, subscriptionID: subscriptionID)
                    L.d("[iot] subscribe rejected =>", topic, suback.reasonCodes, suback.reasonString ?? "")
                }
                return
            } catch {
                guard attempt < maximumSubscriptionAttempts else {
                    removeTopicHandler(topic, subscriptionID: subscriptionID)
                    L.d("[iot]subscribe error =>", topic, error)
                    return
                }
                L.d("[iot]subscribe retry =>", topic, attempt, error)
                try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
            }
        }
    }

    func unsubscribeTopic(_ topic: String) {
        lock.chIoTWithLock { topicHandlers.removeValue(forKey: topic) }
        Task {
            do {
                let mqttClient = try mqttClient()
                _ = try await mqttClient.unsubscribe(
                    unsubscribePacket: UnsubscribePacket(topicFilter: topic)
                )
            } catch {
                L.d("[iot]unsubscribe error =>", topic, error)
            }
        }
    }

    // MARK: - Unsubscribe WM2
    func unsubscribeWifiModule2Shadow(_ device: CHWifiModule2) {
        guard let uuid = device.deviceId?.uuidString else {
            return
        }
        let shadowName = uuid.split(separator: "-").last!
        unsubscribeTopic("$aws/things/wm2/shadow/name/\(shadowName)/update/accepted")
    }

    // MARK: - Subscribe Sesame2
    func subscribeCHDeviceShadow(_ device: CHDevice,
                                 onResponse: @escaping (CHResult<CHDeviceShadow>)) {
        func subscirbe() {
            L.d("[iot]subscirbeCHDeviceShadow =>",device.deviceId.uuidString)
            self.subscribeTopic("$aws/things/sesame2/shadow/name/\(device.deviceId.uuidString)/update/documents") { data in
                let shadow = CHDeviceShadow.fromData(data)
                onResponse(.success(.init(input: shadow)))
            }
        }
        if lock.chIoTWithLock({ connectionStatus }) != .connected {
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
        unsubscribeTopic("$aws/things/sesame2/shadow/name/\(uuid)/update/documents")
    }

    private func mqttClient() throws -> Mqtt5Client {
        clientCreationLock.lock()
        defer { clientCreationLock.unlock() }
        if let client = lock.chIoTWithLock({ client }) {
            return client
        }

        let endpoint = URL(string: AWSConfig.iotEndpoint)?.host ?? AWSConfig.iotEndpoint
        let mqttCredentialsProvider = try CredentialsProvider(provider: credentialsProvider)
        let builder = try Mqtt5ClientBuilder.websocketsWithDefaultAwsSigning(
            endpoint: endpoint,
            region: CHConfiguration.shared.regionName,
            credentialsProvider: mqttCredentialsProvider
        )
        builder.withClientId(UUID().uuidString)
        builder.withClientSessionBehaviorType(.clean)
        builder.withKeepAliveInterval(60)
        builder.withMinReconnectDelay(1)
        builder.withMaxReconnectDelay(128)
        builder.withMinConnectedTimeToResetReconnectDelay(20)
        builder.withCallbacks(
            onPublishReceived: { [weak self] data in
                self?.callbackQueue.async { [weak self] in
                    self?.handlePublish(topic: data.publishPacket.topic,
                                        payload: data.publishPacket.payload)
                }
            },
            onLifecycleEventAttemptingConnect: { [weak self] _ in
                self?.enqueueStatus(.connecting)
            },
            onLifecycleEventConnectionSuccess: { [weak self] data in
                L.d("[iot] MQTT connected, rejoined session =>", data.negotiatedSettings.rejoinedSession)
                self?.enqueueStatus(.connected)
            },
            onLifecycleEventConnectionFailure: { [weak self] data in
                L.d("[iot] MQTT connection failure =>", data.crtError.code, data.crtError.message)
                self?.handleConnectionFailure(code: Int(data.crtError.code))
            },
            onLifecycleEventDisconnection: { [weak self] data in
                L.d("[iot] MQTT disconnected =>", data.crtError.code, data.crtError.message)
                self?.enqueueStatus(.disconnected)
            },
            onLifecycleEventStopped: { [weak self] _ in
                self?.callbackQueue.async { [weak self] in
                    guard let self else { return }
                    let shouldRestart = self.lock.chIoTWithLock { () -> Bool in
                        self.clientStarted = false
                        self.client = nil
                        self.consecutiveWebSocketFailures = 0
                        self.clientRecoveryRequested = false
                        return self.networkAvailable
                    }
                    self.statusCallback(.disconnected)
                    if shouldRestart {
                        self.reconnect()
                    }
                }
            }
        )

        let newClient = try builder.build()
        lock.chIoTWithLock {
            client = newClient
        }
        return newClient
    }

    private func handlePublish(topic: String, payload: Data?) {
        guard let payload,
              let callback = lock.chIoTWithLock({ topicHandlers[topic]?.callback }) else {
            return
        }
        callback(payload)
    }

    private func removeTopicHandler(_ topic: String, subscriptionID: UUID) {
        lock.chIoTWithLock {
            guard topicHandlers[topic]?.subscriptionID == subscriptionID else { return }
            topicHandlers.removeValue(forKey: topic)
        }
    }
}///end

private extension NSLock {
    func chIoTWithLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
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
        
        CHAPIClient.shared.sendIoTCommand(
            deviceId: device.deviceId.uuidString,
            command: command,
            history: hisTag,
            sign: keyCheck[0...3].toHexString()
        ) { apiResult in
            onResponse(apiResult)
        }
    }
}

#if os(watchOS)
final class CHIoTManager {
    static let shared = CHIoTManager()
    func subscribeTopic(_ topic: String, callback: @escaping (Data) -> Void) { }
    func unsubscribeTopic(_ topic: String) { }
}

#endif
