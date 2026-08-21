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
    private final class ConnectionSlot: @unchecked Sendable {
        let id: Int
        let generation: UInt64
        var client: Mqtt5Client?
        var clientToken: UUID?
        var status: CHIoTConnectionStatus = .disconnected
        var clientStarted = false
        var assignedTopics = Set<String>()
        var subscribedTopics = Set<String>()
        var subscribingTopics = Set<String>()
        var subscriptionTask: Task<Void, Never>?
        var consecutiveWebSocketFailures = 0
        var clientRecoveryRequested = false
        var lastClientRecoveryAt: Date?

        init(id: Int, generation: UInt64) {
            self.id = id
            self.generation = generation
        }
    }

    private struct TopicHandler {
        let subscriptionID: UUID
        var callback: (Data) -> Void
    }

    static let shared = CHIoTManager()
    private let maximumTopicsPerConnection = 50
    private let maximumSubscriptionAttempts = 3
    private let subscriptionRetryDelay: TimeInterval = 5
    private let clientRecoveryCooldown: TimeInterval = 60
    private let lock = NSLock()
    private let clientCreationLock = NSLock()
    private let callbackQueue = DispatchQueue(label: "co.candyhouse.sesame.iot.callback")
    private let credentialsProvider: any CredentialsProviding
    private var connectionSlots: [ConnectionSlot] = []
    private var topicHandlers: [String: TopicHandler] = [:]
    private var topicSlots: [String: ConnectionSlot] = [:]
    private var topicOwners: [String: String] = [:]
    private var deviceTopics: [String: Set<String>] = [:]
    private var connectionStatus: CHIoTConnectionStatus = .unknown
    private var networkAvailable = true
    private var poolStarted = false
    private var poolGeneration: UInt64 = 0
    private var nextSlotID = 1

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
        let slotsToStart = lock.chIoTWithLock { () -> [ConnectionSlot] in
            poolStarted = true
            if connectionSlots.isEmpty {
                connectionSlots.append(createConnectionSlotLocked())
            }
            return connectionSlots.filter { !$0.clientStarted }
        }
        slotsToStart.forEach(startSlot)
    }

    func stopConnectionPool() {
        let clients = lock.chIoTWithLock { () -> [Mqtt5Client] in
            poolStarted = false
            poolGeneration &+= 1
            connectionStatus = .disconnected

            let clients = connectionSlots.compactMap(\.client)
            connectionSlots.forEach { $0.subscriptionTask?.cancel() }
            connectionSlots.removeAll()
            topicHandlers.removeAll()
            topicSlots.removeAll()
            topicOwners.removeAll()
            deviceTopics.removeAll()
            return clients
        }
        clients.forEach { client in
            do {
                try client.stop()
            } catch {
                L.d("[iot] stop MQTT pool client error =>", error)
            }
        }
    }

    func restartConnectionPool() {
        stopConnectionPool()
        reconnect()
    }

    private func networkStatusChanged(_ status: NetworkReachabilityStatus) {
        callbackQueue.async { [weak self] in
            guard let self else { return }
            switch status {
            case .notReachable:
                let result = self.lock.chIoTWithLock { () -> ([Mqtt5Client], CHIoTConnectionStatus)? in
                    guard self.networkAvailable else { return nil }
                    self.networkAvailable = false
                    let previousStatus = self.connectionStatus
                    self.connectionSlots.forEach { slot in
                        slot.status = .disconnected
                        slot.subscribedTopics.removeAll()
                        slot.subscribingTopics.removeAll()
                        slot.subscriptionTask?.cancel()
                        slot.subscriptionTask = nil
                    }
                    self.updatePoolStatusLocked()
                    return (self.connectionSlots.compactMap(\.client), previousStatus)
                }
                guard let result else { return }
                L.d("[iot] network unavailable, stopping MQTT")
                self.handlePoolStatusChange(from: result.1)
                result.0.forEach { client in
                    do {
                        try client.stop()
                    } catch {
                        L.d("[iot] stop MQTT error =>", error)
                    }
                }
            case .reachable:
                let slotsToStart = self.lock.chIoTWithLock { () -> [ConnectionSlot] in
                    self.networkAvailable = true
                    guard self.poolStarted else { return [] }
                    return self.connectionSlots.filter { !$0.clientStarted }
                }
                L.d("[iot] network available")
                slotsToStart.forEach(self.startSlot)
            case .unknown:
                break
            }
        }
    }

    private func handleConnectionFailure(_ slot: ConnectionSlot, token: UUID, code: Int) {
        callbackQueue.async { [weak self] in
            guard let self else { return }
            let clientToStop = self.lock.chIoTWithLock { () -> Mqtt5Client? in
                guard self.isCurrentClientLocked(slot, token: token) else { return nil }
                guard code == 2065 else {
                    slot.consecutiveWebSocketFailures = 0
                    return nil
                }
                slot.consecutiveWebSocketFailures += 1
                guard slot.consecutiveWebSocketFailures >= 3,
                      self.networkAvailable,
                      slot.clientStarted,
                      !slot.clientRecoveryRequested else {
                    return nil
                }
                let now = Date()
                if let lastRecoveryAt = slot.lastClientRecoveryAt,
                   now.timeIntervalSince(lastRecoveryAt) < self.clientRecoveryCooldown {
                    return nil
                }
                slot.consecutiveWebSocketFailures = 0
                slot.clientRecoveryRequested = true
                slot.lastClientRecoveryAt = now
                return slot.client
            }
            guard let clientToStop else { return }

            L.d("[iot] rebuilding MQTT client after repeated WebSocket failures, slot =>", slot.id)
            do {
                try clientToStop.stop()
            } catch {
                self.lock.chIoTWithLock {
                    slot.clientRecoveryRequested = false
                }
                L.d("[iot] stop failed MQTT client error =>", error)
            }
        }
    }

    private func updateSlotStatus(_ slot: ConnectionSlot,
                                  token: UUID,
                                  status: CHIoTConnectionStatus) {
        let previousStatus = lock.chIoTWithLock { () -> CHIoTConnectionStatus? in
            guard isCurrentClientLocked(slot, token: token) else { return nil }
            let previousStatus = connectionStatus
            if status == .connected {
                slot.consecutiveWebSocketFailures = 0
                slot.subscribedTopics.removeAll()
                slot.subscribingTopics.removeAll()
            } else {
                slot.subscribedTopics.removeAll()
                slot.subscribingTopics.removeAll()
                slot.subscriptionTask?.cancel()
                slot.subscriptionTask = nil
            }
            slot.status = status
            updatePoolStatusLocked()
            return previousStatus
        }
        guard let previousStatus else { return }

        if status == .connected {
            subscribeAssignedTopics(slot)
        }
        handlePoolStatusChange(from: previousStatus)
    }

    private func handlePoolStatusChange(from previousStatus: CHIoTConnectionStatus) {
        let currentStatus = lock.chIoTWithLock { connectionStatus }
        guard currentStatus != previousStatus else { return }
        L.d("[iot] MQTT pool status =>", previousStatus.rawValue, currentStatus.rawValue)

        if previousStatus == .connected, currentStatus != .connected {
            CHDeviceManager.shared.getCHDevices { getResult in
                if case let .success(devices) = getResult {
                    for device in devices.data {
                        device.deviceShadowStatus = nil
                        device.makeIoTStatusToDisconnect()
                    }
                }
            }
        } else if previousStatus != .connected, currentStatus == .connected {
            CHDeviceManager.shared.getCHDevices { getResult in
                if case let .success(devices) = getResult {
                    for device in devices.data {
                        (device as? CHDeviceUtil)?.goIOT()
                    }
                }
            }
        }

        if previousStatus == .disconnected, currentStatus == .connecting {
            CHAPIClient.shared.getCHUserKeys { _ in }
        }
    }

    // MARK: - Subscribe wm2 shadow
    func subscribeWifiModule2Shadow(_ wifiModule2: CHWifiModule2,
                                    onResponse: @escaping (CHResult<WifiModuleShadow>)) {
        let shadowName = wifiModule2.deviceId.uuidString.split(separator: "-").last!
        subscribeTopic("$aws/things/wm2/shadow/name/\(shadowName)/update/accepted",
                       device: wifiModule2) { data in
            let parser: WifiModuleShadow.Type = wifiModule2.productModel == .hub3 ? Hub3Shadow.self : WifiModule2Shadow.self
            onResponse(.success(.init(input: parser.fromData(data))))
        }
    }

    func subscribeTopic(_ topic: String,
                        device: CHDevice? = nil,
                        callback: @escaping (Data) -> Void) {
        let subscriptionID = UUID()
        var shouldReconnect = false
        var slotToStart: ConnectionSlot?
        var slotToSubscribe: ConnectionSlot?
        lock.chIoTWithLock {
            guard poolStarted else {
                shouldReconnect = true
                return
            }
            if var handler = topicHandlers[topic] {
                handler.callback = callback
                topicHandlers[topic] = handler
            } else {
                topicHandlers[topic] = TopicHandler(
                    subscriptionID: subscriptionID,
                    callback: callback
                )
            }

            if let deviceID = device?.deviceId?.uuidString.lowercased() {
                if let previousOwner = topicOwners[topic], previousOwner != deviceID {
                    deviceTopics[previousOwner]?.remove(topic)
                }
                topicOwners[topic] = deviceID
                deviceTopics[deviceID, default: []].insert(topic)
            }

            if let existingSlot = topicSlots[topic] {
                if existingSlot.status == .connected,
                   !existingSlot.subscribedTopics.contains(topic) {
                    slotToSubscribe = existingSlot
                }
                return
            }

            let slot = connectionSlots.first {
                $0.status == .connected && $0.assignedTopics.count < maximumTopicsPerConnection
            } ?? connectionSlots.first {
                $0.assignedTopics.count < maximumTopicsPerConnection
            } ?? createConnectionSlotLocked()

            if !connectionSlots.contains(where: { $0 === slot }) {
                connectionSlots.append(slot)
            }
            slot.assignedTopics.insert(topic)
            topicSlots[topic] = slot

            if slot.status == .connected {
                slotToSubscribe = slot
            } else if !slot.clientStarted {
                slotToStart = slot
            }
        }
        if shouldReconnect {
            reconnect()
            return
        }
        if let slotToStart {
            startSlot(slotToStart)
        }
        if let slotToSubscribe {
            enqueueSubscription(slotToSubscribe, topic: topic)
        }
    }

    private func subscribe(_ slot: ConnectionSlot, topic: String) async {
        let subscription = lock.chIoTWithLock { () -> (Mqtt5Client, UUID, UUID)? in
            guard isActiveSlotLocked(slot),
                  slot.status == .connected,
                  slot.assignedTopics.contains(topic),
                  !slot.subscribedTopics.contains(topic),
                  !slot.subscribingTopics.contains(topic),
                  let client = slot.client,
                  let token = slot.clientToken,
                  let subscriptionID = topicHandlers[topic]?.subscriptionID else {
                return nil
            }
            slot.subscribingTopics.insert(topic)
            return (client, token, subscriptionID)
        }
        guard let (client, token, subscriptionID) = subscription else { return }

        defer {
            lock.chIoTWithLock { slot.subscribingTopics.remove(topic) }
        }

        for attempt in 1...maximumSubscriptionAttempts {
            let isCurrentSubscription = lock.chIoTWithLock { () -> Bool in
                isCurrentClientLocked(slot, token: token) &&
                    slot.status == .connected &&
                    slot.assignedTopics.contains(topic) &&
                    topicHandlers[topic]?.subscriptionID == subscriptionID
            }
            guard isCurrentSubscription else { return }

            do {
                let suback = try await client.subscribe(
                    subscribePacket: SubscribePacket(topicFilter: topic, qos: .atMostOnce)
                )
                if suback.reasonCodes.contains(where: { $0.rawValue >= 128 }) {
                    L.d("[iot] subscribe rejected, slot =>", slot.id, topic, suback.reasonCodes, suback.reasonString ?? "")
                } else {
                    lock.chIoTWithLock {
                        if isCurrentClientLocked(slot, token: token),
                           slot.assignedTopics.contains(topic),
                           topicHandlers[topic]?.subscriptionID == subscriptionID {
                            slot.subscribedTopics.insert(topic)
                        }
                    }
                    return
                }
            } catch {
                L.d("[iot] subscribe error, slot =>", slot.id, topic, error)
            }

            if attempt < maximumSubscriptionAttempts {
                try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
            }
        }

        callbackQueue.asyncAfter(deadline: .now() + subscriptionRetryDelay) { [weak self, weak slot] in
            guard let self, let slot else { return }
            self.enqueueSubscription(slot, topic: topic)
        }
    }

    func unsubscribeTopic(_ topic: String) {
        let unsubscription = lock.chIoTWithLock { () -> (ConnectionSlot, Mqtt5Client, UUID)? in
            topicHandlers.removeValue(forKey: topic)
            if let owner = topicOwners.removeValue(forKey: topic) {
                deviceTopics[owner]?.remove(topic)
                if deviceTopics[owner]?.isEmpty == true {
                    deviceTopics.removeValue(forKey: owner)
                }
            }
            guard let slot = topicSlots.removeValue(forKey: topic) else { return nil }
            slot.assignedTopics.remove(topic)
            slot.subscribedTopics.remove(topic)
            slot.subscribingTopics.remove(topic)
            guard slot.status == .connected,
                  let client = slot.client,
                  let token = slot.clientToken else { return nil }
            return (slot, client, token)
        }
        guard let (slot, client, token) = unsubscription else { return }
        enqueueUnsubscription(slot, client: client, token: token, topic: topic)
    }

    func unsubscribeDevice(_ deviceID: UUID) {
        let topics = lock.chIoTWithLock {
            deviceTopics[deviceID.uuidString.lowercased()]?.sorted() ?? []
        }
        topics.forEach(unsubscribeTopic)
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
            self.subscribeTopic("$aws/things/sesame2/shadow/name/\(device.deviceId.uuidString)/update/documents",
                                device: device) { data in
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

    private func createConnectionSlotLocked() -> ConnectionSlot {
        let slot = ConnectionSlot(id: nextSlotID, generation: poolGeneration)
        nextSlotID += 1
        return slot
    }

    private func startSlot(_ slot: ConnectionSlot) {
        let shouldStart = lock.chIoTWithLock { () -> Bool in
            guard isActiveSlotLocked(slot), networkAvailable, !slot.clientStarted else { return false }
            slot.clientStarted = true
            slot.status = .connecting
            let previousStatus = connectionStatus
            updatePoolStatusLocked()
            callbackQueue.async { [weak self] in
                self?.handlePoolStatusChange(from: previousStatus)
            }
            return true
        }
        guard shouldStart else { return }

        do {
            let mqttClient = try mqttClient(for: slot)
            try mqttClient.start()
        } catch {
            let previousStatus = lock.chIoTWithLock { () -> CHIoTConnectionStatus in
                let previousStatus = connectionStatus
                if isActiveSlotLocked(slot) {
                    slot.clientStarted = false
                    slot.status = .connectionError
                    updatePoolStatusLocked()
                }
                return previousStatus
            }
            handlePoolStatusChange(from: previousStatus)
            L.d("[iot] start MQTT slot error =>", slot.id, error)
        }
    }

    private func mqttClient(for slot: ConnectionSlot) throws -> Mqtt5Client {
        clientCreationLock.lock()
        defer { clientCreationLock.unlock() }
        if let client = lock.chIoTWithLock({ slot.client }) {
            return client
        }

        let clientToken = UUID()
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
            onPublishReceived: { [weak self, weak slot] data in
                self?.callbackQueue.async { [weak self] in
                    guard let slot else { return }
                    self?.handlePublish(slot: slot,
                                        token: clientToken,
                                        topic: data.publishPacket.topic,
                                        payload: data.publishPacket.payload)
                }
            },
            onLifecycleEventAttemptingConnect: { [weak self, weak slot] _ in
                self?.callbackQueue.async { [weak self, weak slot] in
                    guard let self, let slot else { return }
                    self.updateSlotStatus(slot, token: clientToken, status: .connecting)
                }
            },
            onLifecycleEventConnectionSuccess: { [weak self, weak slot] data in
                guard let slot else { return }
                L.d("[iot] MQTT connected, slot/rejoined session =>", slot.id, data.negotiatedSettings.rejoinedSession)
                self?.callbackQueue.async { [weak self, weak slot] in
                    guard let self, let slot else { return }
                    self.updateSlotStatus(slot, token: clientToken, status: .connected)
                }
            },
            onLifecycleEventConnectionFailure: { [weak self, weak slot] data in
                guard let slot else { return }
                L.d("[iot] MQTT connection failure, slot =>", slot.id, data.crtError.code, data.crtError.message)
                self?.callbackQueue.async { [weak self, weak slot] in
                    guard let self, let slot else { return }
                    self.updateSlotStatus(slot, token: clientToken, status: .connectionError)
                }
                self?.handleConnectionFailure(slot, token: clientToken, code: Int(data.crtError.code))
            },
            onLifecycleEventDisconnection: { [weak self, weak slot] data in
                guard let slot else { return }
                L.d("[iot] MQTT disconnected, slot =>", slot.id, data.crtError.code, data.crtError.message)
                self?.callbackQueue.async { [weak self, weak slot] in
                    guard let self, let slot else { return }
                    self.updateSlotStatus(slot, token: clientToken, status: .disconnected)
                }
            },
            onLifecycleEventStopped: { [weak self, weak slot] _ in
                self?.callbackQueue.async { [weak self, weak slot] in
                    guard let self, let slot else { return }
                    let result = self.lock.chIoTWithLock { () -> (Bool, CHIoTConnectionStatus)? in
                        guard self.isCurrentClientLocked(slot, token: clientToken) else { return nil }
                        let previousStatus = self.connectionStatus
                        slot.clientStarted = false
                        slot.client = nil
                        slot.clientToken = nil
                        slot.status = .disconnected
                        slot.subscribedTopics.removeAll()
                        slot.subscribingTopics.removeAll()
                        slot.subscriptionTask?.cancel()
                        slot.subscriptionTask = nil
                        slot.consecutiveWebSocketFailures = 0
                        slot.clientRecoveryRequested = false
                        self.updatePoolStatusLocked()
                        return (self.poolStarted && self.networkAvailable, previousStatus)
                    }
                    guard let result else { return }
                    self.handlePoolStatusChange(from: result.1)
                    if result.0 {
                        self.startSlot(slot)
                    }
                }
            }
        )

        let newClient = try builder.build()
        let accepted = lock.chIoTWithLock { () -> Bool in
            guard isActiveSlotLocked(slot), slot.client == nil else { return false }
            slot.client = newClient
            slot.clientToken = clientToken
            return true
        }
        guard accepted else {
            try? newClient.stop()
            throw NSError(domain: "CHIoTManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "MQTT connection slot is no longer active"])
        }
        return newClient
    }

    private func subscribeAssignedTopics(_ slot: ConnectionSlot) {
        let topics = lock.chIoTWithLock { () -> [String] in
            guard isActiveSlotLocked(slot), slot.status == .connected else { return [] }
            return slot.assignedTopics.sorted()
        }
        topics.forEach { enqueueSubscription(slot, topic: $0) }
    }

    private func enqueueSubscription(_ slot: ConnectionSlot, topic: String) {
        lock.chIoTWithLock {
            guard isActiveSlotLocked(slot),
                  slot.status == .connected,
                  slot.assignedTopics.contains(topic),
                  !slot.subscribedTopics.contains(topic),
                  !slot.subscribingTopics.contains(topic) else { return }
            let previousTask = slot.subscriptionTask
            slot.subscriptionTask = Task { [weak self, weak slot] in
                await previousTask?.value
                guard !Task.isCancelled, let self, let slot else { return }
                await self.subscribe(slot, topic: topic)
            }
        }
    }

    private func enqueueUnsubscription(_ slot: ConnectionSlot,
                                       client: Mqtt5Client,
                                       token: UUID,
                                       topic: String) {
        lock.chIoTWithLock {
            let previousTask = slot.subscriptionTask
            slot.subscriptionTask = Task { [weak self, weak slot] in
                await previousTask?.value
                guard !Task.isCancelled, let self, let slot else { return }
                let shouldUnsubscribe = self.lock.chIoTWithLock {
                    self.isCurrentClientLocked(slot, token: token) &&
                        !slot.assignedTopics.contains(topic)
                }
                guard shouldUnsubscribe else { return }
                do {
                    _ = try await client.unsubscribe(
                        unsubscribePacket: UnsubscribePacket(topicFilter: topic)
                    )
                } catch {
                    L.d("[iot] unsubscribe error, slot =>", slot.id, topic, error)
                }
            }
        }
    }

    private func handlePublish(slot: ConnectionSlot,
                               token: UUID,
                               topic: String,
                               payload: Data?) {
        guard let payload,
              let callback = lock.chIoTWithLock({ () -> ((Data) -> Void)? in
                  guard isCurrentClientLocked(slot, token: token), topicSlots[topic] === slot else { return nil }
                  return topicHandlers[topic]?.callback
              }) else {
            return
        }
        callback(payload)
    }

    private func isActiveSlotLocked(_ slot: ConnectionSlot) -> Bool {
        poolStarted && slot.generation == poolGeneration && connectionSlots.contains(where: { $0 === slot })
    }

    private func isCurrentClientLocked(_ slot: ConnectionSlot, token: UUID) -> Bool {
        isActiveSlotLocked(slot) && slot.clientToken == token && slot.client != nil
    }

    private func updatePoolStatusLocked() {
        if connectionSlots.contains(where: { $0.status == .connected }) {
            connectionStatus = .connected
        } else if connectionSlots.contains(where: { $0.status == .connecting }) {
            connectionStatus = .connecting
        } else if connectionSlots.contains(where: { $0.status == .connectionError }) {
            connectionStatus = .connectionError
        } else {
            connectionStatus = .disconnected
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
    func subscribeTopic(_ topic: String,
                        device: CHDevice? = nil,
                        callback: @escaping (Data) -> Void) { }
    func unsubscribeTopic(_ topic: String) { }
}

#endif
