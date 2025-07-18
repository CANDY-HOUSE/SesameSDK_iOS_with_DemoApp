//
//  CHDelegateManager.swift
//  SesameSDK
//
//  Created by wuying on 2025/4/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
public class CHDelegateManager {
    // 类型擦除的委托容器
    private class DelegateBox {
        weak var delegate: AnyObject?
        
        init(_ delegate: AnyObject) {
            self.delegate = delegate
        }
    }
    
    // 使用字符串作为键，委托数组作为值
    private var delegateBoxes: [String: [DelegateBox]] = [:]
    
    // 注册委托（接受任何遵循 AnyObject 的类型）
    public func register(_ delegate: AnyObject, for type: Any.Type) {
        let key = String(describing: type)
        
        if delegateBoxes[key] == nil {
            delegateBoxes[key] = []
        }
        
        // 检查是否已经注册
        if !delegateBoxes[key]!.contains(where: { $0.delegate === delegate }) {
            delegateBoxes[key]?.append(DelegateBox(delegate))
        }
        
        // 清理无效引用
        cleanUp(for: key)
    }
    
    // 注销委托
    public func unregister(_ delegate: AnyObject, for type: Any.Type) {
        let key = String(describing: type)
        delegateBoxes[key]?.removeAll { $0.delegate === delegate }
    }
    
    // 获取特定类型的所有委托
    public func delegates<T>(of type: T.Type) -> [T] {
        let key = String(describing: type)
        cleanUp(for: key)
        return delegateBoxes[key]?.compactMap { $0.delegate as? T } ?? []
    }
    
    // 通知特定类型的所有委托
    public func notify<T>(_ type: T.Type, handler: (T) -> Void) {
        for delegate in delegates(of: type) {
            handler(delegate)
        }
    }
    
    // 清理无效引用
    private func cleanUp(for key: String) {
        delegateBoxes[key]?.removeAll { $0.delegate == nil }
    }
}
