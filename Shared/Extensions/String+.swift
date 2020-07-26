//
//  String+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/8.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

private class LanguageBundle {
    static let bundle: Bundle = Bundle(for: LanguageBundle.self)
}

extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }

    var bytes: Array<UInt8> {
        return data(using: String.Encoding.utf8, allowLossyConversion: true)?.bytes ?? Array(utf8)
    }
    
    public var localized: String{
        return NSLocalizedString(self,
                                 bundle: LanguageBundle.bundle,
                                 value: "",
                                 comment: "")
    }
}
