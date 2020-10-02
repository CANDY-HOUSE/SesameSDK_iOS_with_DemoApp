//
//  URL+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/8.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension URL {
    
    static var sesame2UI: URL {
        URL(string: "candyhouse://SesameUI/")!
    }
    
    public func sesame2Key() -> String? {
        
        let qreventType = getQuery(name: CHQRKey.QREventType.rawValue)
        guard qreventType == QRcodeType.sharedKey.rawValue else {
            return nil
        }
        
        L.d("scanSchema", self)
        let content = getQuery(name: QRcodeType.sharedKey.rawValue)
        L.d("🔑","content",content)
        
        return content
    }
    
    private func getQuery(name:String) -> String {
        let components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        let value = components?.queryItems?.filter({
            return $0.name == name
        })
        return value?.first?.value ?? "NoData"
    }
}
