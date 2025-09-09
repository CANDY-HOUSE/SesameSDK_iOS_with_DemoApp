//
//  LightControllerRemoteAdapterFactory.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//


class AirControllerRemoteAdapterFactory: RemoteAdapterFactory {
    func createUIConfigAdapter() -> UIConfigAdapter {
        return AirControllerConfigAdapter()
    }
    
    func createHandlerConfigAdapter(uiConfigAdapter: UIConfigAdapter) -> HandlerConfigAdapter {
        return AirControllerHandlerAdapter(uiConfigAdapter: uiConfigAdapter)
    }
}

