//
//  UIConfigAdapter.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

typealias ConfigResult<T> = (Result<T, Error>) -> Void

protocol RemoteUIAdapter {
    /**
     加载界面配置
     - Parameter completion: 完成回调，返回配置或错误
     */
    func loadConfig(completion: @escaping ConfigResult<UIControlConfig>)
    
    /**
     加载界面显示配置
     - Parameter completion: 完成回调，返回UI参数或错误
     */
    func loadUIParams(completion: @escaping ConfigResult<[IrControlItem]>)
    
    /**
     清除配置缓存
     */
    func clearConfigCache()
    
    /**
     处理点击事件
     */
    func handleItemClick(item: IrControlItem, remoteDevice: IRRemote) -> Bool
    
    /**
     设置配置更新回调
     */
    func setConfigUpdateCallback(uiItemCallback: ConfigUpdateCallback)
    
    /**
     设置当前状态
     */
    func setCurrentState(_ state: String?)
    
}
