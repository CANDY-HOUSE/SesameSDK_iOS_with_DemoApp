//
//  LanguageManager.swift
//
//  Created by tse on 2019/9/10.
//  Copyright Candyhouse All rights reserved.
//

import Foundation

fileprivate var bundleKey: UInt8 = 0

func LocalizedString(_ key: String) -> String {
    return LanguageManager.shared.getLocalizedString(key)
}

public class LanguageManager {
    static let shared = LanguageManager()
    var current: Language {
        get {
            if let list = UserDefaults.standard.value(forKey: "AppleLanguages") as? [String], let lang = list.first {
                return Language(rawValue: lang) ?? .japanese
            }
            return .japanese
        }
        set {
            if newValue == .english {
                UserDefaults.standard.setValue(nil, forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.setValue([newValue.rawValue], forKey: "AppleLanguages")
            }
            Bundle.setLanguage(newValue.rawValue)
        }
    }
    
    func supportedLanguages() -> [Language] {
        return Language.allCases
    }
    
    func getLocalizedString(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}

fileprivate class LanguageBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let path = objc_getAssociatedObject(self, &bundleKey) as? String, let bundle = Bundle(path: path) else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

fileprivate extension Bundle {
    class func setLanguage(_ code: String) {
        defer {
            object_setClass(Constant.resourceBundle, LanguageBundle.self)
        }
        let path = Constant.resourceBundle.path(forResource: code, ofType: "lproj")
        objc_setAssociatedObject(Constant.resourceBundle, &bundleKey, path, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
