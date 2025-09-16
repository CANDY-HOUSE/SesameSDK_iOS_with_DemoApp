//
//  LightControllerRemoteAdapterFactory.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//


class AirAdapterFactory: RemoteAdapterFactory {
    func createUIAdapter(_ uiType: RemoteUIType) -> RemoteUIAdapter {
        return AirUIAdapter(uiType)
    }
    
    func createHandlerAdapter(_ uiAdapter: RemoteUIAdapter) -> RemoteHandlerAdapter {
        return AirHandlerAdapter(uiAdapter)
    }
}

