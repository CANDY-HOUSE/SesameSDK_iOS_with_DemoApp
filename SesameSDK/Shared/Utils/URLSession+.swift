//
//  URLSession+.swift
//  SesameSDK
//  發送請求至awsApiGatewayBaseUrl判斷網路是否連通
//  Created by Wayne Hsiao on 2020/8/21.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension URLSession {
    
    static func isInternetReachable(_ handler: @escaping (Bool)->Void) {
#if os(watchOS)
        let urlSessionConfiguration = URLSessionConfiguration.ephemeral
        if #available(iOS 11.0, *) {
            urlSessionConfiguration.waitsForConnectivity = false
        }
        urlSessionConfiguration.timeoutIntervalForRequest = 3.0
        let url = URL(string: awsApiGatewayBaseUrl)!
        let urlSession = URLSession(configuration: urlSessionConfiguration)
        let task = urlSession.dataTask(with: url, completionHandler: { data, response, error in
            var chIsReachible = true
            if (error as NSError?)?.code == NSURLErrorNotConnectedToInternet ||
                (error as NSError?)?.code == NSURLErrorNetworkConnectionLost {
                chIsReachible = false
            }
            //            L.d("isInternetReachable",URLSession.chIsReachible)
            handler(chIsReachible)
        })
        task.resume()
#else
        handler(NetworkReachabilityHelper.shared.isReachable)
#endif
    }
}

#if canImport(SystemConfiguration)
import SystemConfiguration

public enum NetworkReachabilityStatus: Equatable {
    case unknown
    case notReachable
    case reachable(ConnectionType)
    
    init(_ flags: SCNetworkReachabilityFlags) {
        guard flags.contains(.reachable) else {
            self = .notReachable
            return
        }
        
        if flags.contains(.isWWAN) {
            self = .reachable(.cellular)
        } else {
            self = .reachable(.ethernetOrWiFi)
        }
    }
    public enum ConnectionType {
        case ethernetOrWiFi
        case cellular
    }
}

public class NetworkReachabilityHelper {
    
    public class ClosureWrapper {
        public typealias Listener = (NetworkReachabilityStatus) -> Void
        public let closure: Listener
        
        public init(closure: @escaping Listener) {
            self.closure = closure
        }
    }
    
    public static let shared = NetworkReachabilityHelper()
    
    private var reachability: SCNetworkReachability?
    
    private var weakKeyMap: NSMapTable = NSMapTable<AnyObject, AnyObject>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    
    public private(set) var currentState: NetworkReachabilityStatus = .unknown {
        didSet {
            guard oldValue != currentState else { return }
            DispatchQueue.main.async { [self] in
                self.notifyListenersHandler(currentState)
            }
        }
    }
    
    private init() {
        if let url = URL(string: awsApiGatewayBaseUrl), let host = url.host {
            host.withCString { cString in
                reachability = SCNetworkReachabilityCreateWithName(nil, cString)
            }
        }
        startListening()
    }
    
    public var isReachable: Bool {
        get {
            switch currentState {
            case .reachable:
                return true
            default:
                return false
            }
        }
    }
    
    public func addListener(_ object: AnyObject, _ listener: @escaping ClosureWrapper.Listener) {
        weakKeyMap.setObject(ClosureWrapper(closure: listener), forKey: object)
    }
    
    public func removeListener(_ object: AnyObject) {
        weakKeyMap.removeObject(forKey: object)
    }
    
    private func notifyListenersHandler(_ status: NetworkReachabilityStatus) {
        for val in weakKeyMap.objectEnumerator()?.allObjects as! [ClosureWrapper] {
            val.closure(status)
        }
    }
        
    func startListening() {
        var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        context.info = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let callback: SCNetworkReachabilityCallBack = { _, flags, info in
            guard let info = info else { return }
            let mySelf = Unmanaged<NetworkReachabilityHelper>.fromOpaque(info).takeUnretainedValue()
            mySelf.currentState = NetworkReachabilityStatus(flags)
        }
        if SCNetworkReachabilitySetCallback(reachability!, callback, &context) {
            SCNetworkReachabilityScheduleWithRunLoop(reachability!, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        }
    }
    
    func stopListening() {
        if let reachability = reachability {
            SCNetworkReachabilityUnscheduleFromRunLoop(reachability, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        }
    }
    
    deinit {
        stopListening()
    }
}
#endif
