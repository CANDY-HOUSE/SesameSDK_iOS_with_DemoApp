//
//  TVControllerRemoteAdapterFactory.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

class TVControllerRemoteAdapterFactory: RemoteAdapterFactory {
    func createUIConfigAdapter() -> UIConfigAdapter {
        return TVControllerConfigAdapter()
    }
    
    func createHandlerConfigAdapter(uiConfigAdapter: UIConfigAdapter) -> HandlerConfigAdapter {
        return TVControllerHandlerAdapter(uiConfigAdapter: uiConfigAdapter)
    }
}
