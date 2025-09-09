//
//  LightControllerRemoteAdapterFactory.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//


class LightControllerRemoteAdapterFactory: RemoteAdapterFactory {
    func createUIConfigAdapter() -> UIConfigAdapter {
        return LightControllerConfigAdapter()
    }
    
    func createHandlerConfigAdapter(uiConfigAdapter: UIConfigAdapter) -> HandlerConfigAdapter {
        return LightControllerHandlerAdapter(uiConfigAdapter: uiConfigAdapter)
    }
}

