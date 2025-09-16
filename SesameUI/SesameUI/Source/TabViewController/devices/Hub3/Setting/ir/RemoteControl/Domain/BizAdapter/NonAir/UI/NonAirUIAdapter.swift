//
//  NonAirUIAdapter.swift
//  SesameUI
//
//  Created by CANDY HOUSE on 2025/9/14.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK


class NonAirUIAdapter: RemoteUIAdapter {
    
    private let tag = String(describing: NonAirUIAdapter.self)
    private var config: UIControlConfig?
    private var updateCallback: ConfigUpdateCallback?
    private var currentCode: Int = -1
    private var currentState: String = ""
    let uiType: RemoteUIType
    
    let commandProcessor = HXDCommandProcessor()
    let paramsSwapper = HXDParametersSwapper()
    
    init(_ uiType: RemoteUIType) {
        self.uiType = uiType
    }
    
    func loadConfig(completion: @escaping ConfigResult<UIControlConfig>) {
        if let config = self.config {
            completion(.success(config))
            return
        }
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            var config: UIControlConfig?
            let result = LoadRemoteConfig.loadJsonObject(uiType.rawValue, result: &config)
            
            executeOnMainThread {
                if result, let config = config {
                    self.config = config
                    completion(.success(config))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load config"])))
                }
            }
        }
    }
    
    func loadUIParams(completion: @escaping ConfigResult<[IrControlItem]>) {
        guard let config = self.config else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Config is null"])))
            return
        }
        let items = createControlItems(config: config)
        completion(.success(items))
    }
    
    func clearConfigCache() {
        config = nil
    }
    
    func setConfigUpdateCallback(uiItemCallback: ConfigUpdateCallback) {
        self.updateCallback = uiItemCallback
    }
    
    func handleItemClick(item: IrControlItem, remoteDevice: IRRemote) -> Bool {
        updateCallback?.onItemUpdate(item)
        return true
    }
    
    private func createControlItems(config: UIControlConfig) -> [IrControlItem] {
        return config.controls.map { controlConfig in
            let type = ItemType(rawValue: controlConfig.type) ?? .powerStatusOn
            return IrControlItem(
                id: controlConfig.id,
                type: type,
                title: controlConfig.titles[0].localized,
                value: "",
                isSelected: true,
                iconRes: "",
                optionCode: controlConfig.operateCode
            )
        }
    }
    
    func getCurrentState() -> String {
        return currentState
    }
    
    func setCurrentState(_ state: String?) {
        currentState = state ?? ""
    }
}
