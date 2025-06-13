//
//  IRServiceRegistry.swift
//  SesameUI
//
//  Created by eddy on 2024/7/15.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation

class IRServiceRegistry {
    static let shared = IRServiceRegistry()
    private var services = [String: NSObject]()
    
    private init() {
    }
    
    func register(serviceClass: NSObject.Type) {
        let uniqueKey = "\(serviceClass.self)"
        services[uniqueKey] = serviceClass.init()
    }
    
    func unregister(serviceClass: NSObject.Type) {
        let uniqueKey = "\(serviceClass.self)"
        services.removeValue(forKey: uniqueKey)
    }
    
    func service(_ forKey: String) -> AnyObject? {
        return services[forKey]
    }
}

extension IRServiceRegistry {
    func setup(){
        let serviceCls = [
//            IRLearningViewModel.self,
            IRDeviceService.self
        ]
        for cls in serviceCls {
            register(serviceClass: cls)
        }
    }
}

//extension IRLearningViewModel {
//    static func fromRegistry() -> IRLearningViewModel {
//        return IRServiceRegistry.shared.service("\(IRLearningViewModel.self)") as! IRLearningViewModel
//    }
//}

extension IRDeviceService {
    static func fromRegistry() -> IRDeviceService {
        return IRServiceRegistry.shared.service("\(IRDeviceService.self)") as! IRDeviceService
    }
    
    static func groupFromRegistry(_ deviceId: String) -> ETGroup? {
        let service = fromRegistry()
        return service.deviceById(deviceId)
    }
}
