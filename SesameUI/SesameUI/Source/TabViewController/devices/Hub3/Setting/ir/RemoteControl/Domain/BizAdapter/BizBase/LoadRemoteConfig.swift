//
//  BastUtils.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK


class LoadRemoteConfig {
    
    static func loadJsonArray<T: Decodable>(_ name: String, result: inout [T]) -> Bool {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            L.d("JsonLoader", "\(name).json is not exist!")
            return false
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            do {
                result = try decoder.decode([T].self, from: data)
                return true
            } catch let DecodingError.keyNotFound(key, context) {
                return false
            } catch let DecodingError.valueNotFound(type, context) {
                return false
            } catch let DecodingError.typeMismatch(type, context) {
                return false
            } catch let DecodingError.dataCorrupted(context) {
                return false
            } catch {
                return false
            }
        } catch {
            L.d("loadJsonArray", "Failed to load file: \(error)")
            return false
        }
    }
    
    
    static func loadJsonObject<T: Decodable>(_ name: String, result: inout T?) -> Bool {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            L.d("JsonLoader", "\(name).json is not exist!")
            return false
        }
        L.d("JsonLoader", "\(name).json is existed!")
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            
            // 添加更详细的错误处理
            do {
                result = try decoder.decode(T.self, from: data)
                return true
            } catch DecodingError.keyNotFound(let key, let context) {
                L.d("JsonLoader", "Missing key: \(key.stringValue) - \(context.debugDescription)")
            } catch DecodingError.typeMismatch(let type, let context) {
                L.d("JsonLoader", "Type mismatch: \(type) - \(context.debugDescription)")
            } catch DecodingError.valueNotFound(let type, let context) {
                L.d("JsonLoader", "Value not found: \(type) - \(context.debugDescription)")
            } catch DecodingError.dataCorrupted(let context) {
                L.d("JsonLoader", "Data corrupted: \(context.debugDescription)")
            } catch {
                L.d("JsonLoader", "Other decoding error: \(error)")
            }
            
            return false
        } catch {
            L.d("JsonLoader", "Failed to load data: \(error)")
            return false
        }
    }
}
