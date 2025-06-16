//
//  RemoteAdapterFactoryManager.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import SesameSDK

class RemoteAdapterFactoryManager {
    /// 获取对应类型的遥控器适配器工厂
    /// - Parameter type: 遥控器类型
    /// - Returns: 对应类型的适配器工厂
    static func getFactory(type: Int) -> RemoteAdapterFactory? {
        switch type {
        case IRType.DEVICE_REMOTE_AIR:
            return AirControllerRemoteAdapterFactory()
        case IRType.DEVICE_REMOTE_TV:
            return TVControllerRemoteAdapterFactory()
        case IRType.DEVICE_REMOTE_LIGHT:
            return LightControllerRemoteAdapterFactory()
        default:
            L.d("Error!","RemoteAdapterFactoryManager getFactory type=\(type)")
            return nil
        }
    }
}
