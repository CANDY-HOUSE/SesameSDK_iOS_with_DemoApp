//
//  NonAirAdapterFactory.swift
//  SesameUI
//
//  Created by CANDY HOUSE on 2025/9/14.
//  Copyright © 2025 CandyHouse. All rights reserved.
//


class NonAirAdapterFactory : RemoteAdapterFactory {
    
    func createUIAdapter(_ uiType: RemoteUIType) -> RemoteUIAdapter {
        return NonAirUIAdapter(uiType)
    }
    
    func createHandlerAdapter(_ uiConfigAdapter: RemoteUIAdapter) -> RemoteHandlerAdapter {
        return NonAirHandlerAdapter(uiConfigAdapter)
    }
}
