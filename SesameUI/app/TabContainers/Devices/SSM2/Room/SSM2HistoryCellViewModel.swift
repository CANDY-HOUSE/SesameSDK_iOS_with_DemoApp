//
//  SSM2HistoryCellViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

public final class SSM2HistoryCellViewModel: ViewModel {
    public var statusUpdated: ViewStatusHandler?
    
    let history: Sesame2History
    
    init(history: Sesame2History) {
        self.history = history
    }
    
    public func timeLabelText() -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(history.timeStamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss a"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        return dateFormatter.string(from: date)
    }
    
    public var eventImage: String {
        ""
    }
    
    public var userLabelText: String {
        ""
    }

    public var avatarImage: String {
        ""
    }
}

public final class SSM2HistoryHeaderCellViewModel {
    private let historys: [Sesame2History]
    
    public init(historys: [Sesame2History]) {
        self.historys = historys
    }
    
    public func userLabelText() -> String {
        guard let first = historys.first else {
            return ""
        }
        return Date(timeIntervalSince1970: TimeInterval(first.timeStamp)).toYMD()
    }
}
