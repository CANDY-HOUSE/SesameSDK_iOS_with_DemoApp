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


class BaseUtils {
    static func showToast(message: String) {
        executeOnMainThread {
            if #available(iOS 13.0, *) {
                // iOS 13 及以上版本
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first else {
                    return
                }
                showToast(message: message, in: window)
            } else {
                // iOS 13 以下版本
                guard let window = UIApplication.shared.keyWindow else {
                    return
                }
                showToast(message: message, in: window)
            }
        }
    }
    
    private static func showToast(message: String, in window: UIWindow) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        toastLabel.numberOfLines = 0
        
        let textSize = toastLabel.intrinsicContentSize
        let labelWidth = min(textSize.width + 40, window.frame.width - 40)
        let labelHeight = max(textSize.height + 20, 40)
        
        toastLabel.frame = CGRect(
            x: (window.frame.width - labelWidth) / 2,
            y: window.frame.height - 100,
            width: labelWidth,
            height: labelHeight
        )
        
        window.addSubview(toastLabel)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            toastLabel.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0
            }, completion: { _ in
                toastLabel.removeFromSuperview()
            })
        })
    }
    
    static func loadJsonArray<T: Decodable>(_ name: String, result: inout [T]) -> Bool {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            L.d("JsonLoader", "\(name).json is not exist!")
            return false
        }
        L.d("JsonLoader", "\(name).json is existed!")
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            do {
                result = try decoder.decode([T].self, from: data)
                return true
            } catch let DecodingError.keyNotFound(key, context) {
                L.d("loadJsonArray", "Missing key '\(key.stringValue)' - \(context.debugDescription)")
                L.d("loadJsonArray", "coding path: \(context.codingPath)")
                return false
            } catch let DecodingError.valueNotFound(type, context) {
                L.d("loadJsonArray", "Missing value of type '\(type)' - \(context.debugDescription)")
                L.d("loadJsonArray", "coding path: \(context.codingPath)")
                return false
            } catch let DecodingError.typeMismatch(type, context) {
                L.d("loadJsonArray", "Type mismatch for type '\(type)' - \(context.debugDescription)")
                L.d("loadJsonArray", "coding path: \(context.codingPath)")
                return false
            } catch let DecodingError.dataCorrupted(context) {
                L.d("loadJsonArray", "Data corrupted - \(context.debugDescription)")
                L.d("loadJsonArray", "coding path: \(context.codingPath)")
                return false
            } catch {
                L.d("loadJsonArray", "Generic error: \(error)")
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
