//
//  URL+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/8.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

extension URL {
    
    static var chURL: URL {
        URL(string: "candyhouse://SesameUI/")!
    }
    
    func queryItemAdded(name: String,  value: String?) -> URL? {
        return self.queryItemsAdded([URLQueryItem(name: name, value: value)])
    }

    func getQuery(name:String) -> String {
        let components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        let value = components?.queryItems?.filter({
            return $0.name == name
        })
        return value?.first?.value ?? "NOdata"

    }

    func queryItemsAdded(_ queryItems: [URLQueryItem]) -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: nil != self.baseURL) else {
            return nil
        }
        components.queryItems = queryItems + (components.queryItems ?? [])
        return components.url
    }
    
    public func ssmKey() -> String? {
        
        let qreventType = getQuery(name: CHQRKey.QREventType.rawValue)
        guard qreventType == CHQREvent.sharedKey.rawValue else {
            return nil
        }
        
        L.d("scanSchema", self)
        let content = getQuery(name: CHQREvent.sharedKey.rawValue)
        L.d("🔑","content",content)
        
        return content
    }
}
