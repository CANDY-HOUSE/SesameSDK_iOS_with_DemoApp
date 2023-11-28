//
//  CHSesame2HistoryEvent.swift
//  Sesame2SDK
//  [joi todo]檔案該改位置
//  Created by YuHan Hsiao on 2020/7/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

class CHSesameHistoryResponse: Codable {
    let histories: [CHSesame2HistoryEvent]
    var cursor: UInt?
}
class CHSesameHistory5Response: Codable {
    let histories: [CHSesame5HistoryEvent]
    var cursor: UInt?
}
class CHSesame2HistoryEvent: Codable {
    public var recordID: Int32  // 事件
    public var type: UInt8  // 事件
    public var timeStamp: UInt64        // 時間戳  ex:166
    public var historyTag: Data?         // 鑰匙標籤             23bytes
    public var devicePk: String?       // 設備本地 ecc public  4bytes
    public var parameter: Data?

    required init(type: Sesame2HistoryTypeEnum ,time: UInt64, recordID: Int32,parameter:Data?=nil) {
        self.type = type.rawValue
        self.timeStamp = time
        self.recordID = recordID
        self.parameter = parameter
    }

    required convenience init(type: Sesame2HistoryTypeEnum ,time: UInt64, recordID: Int32, content: Data,parameter:Data? = nil) {
        self.init(type: type ,time: time, recordID: recordID,parameter:parameter)

        switch type {
        case .BLE_LOCK, .WM2_LOCK, .WEB_LOCK, .BLE_CLICK, .WM2_CLICK, .WEB_CLICK, .MANUAL_CLICK,.BLE_UNLOCK, .WM2_UNLOCK, .WEB_UNLOCK:
            let content = content.copyData
            guard let devicepk = content[safeBound: 2...17] else {
                return
            }
            let histag = content[18...]///2...17 no use devicepk
            let tagcount_historyTag = histag.copyData
            let tagcount = UInt8(tagcount_historyTag[0])
            var historyTag:Data?
            
            if tagcount == 0 {
                historyTag = nil
            } else {
                historyTag = tagcount_historyTag[safeBound: 1...Int(tagcount)]
            }
            self.historyTag = historyTag
//            let hexDevicepk = devicepk.toHexString()
//            self.devicePk = hexDevicepk
        case .NONE:
            break
        case .AUTOLOCK:
            break
        case .MANUAL_LOCKED:
            break
        case .MANUAL_UNLOCKED:
            break
        case .MANUAL_ELSE:
            break
        case .DRIVE_LOCKED:
            break
        case .DRIVE_UNLOCKED:
            break
        case .DRIVE_CLICK:
            break
        case .DRIVE_FAILED:
            let content = content.copyData
            let parameter = content[safeBound: 0...3]
            self.parameter = parameter?.copyData
        }
    }
    
    enum CodingKeys : String, CodingKey {
        case recordID
        case type
        case timeStamp
        case historyTag
        case devicePk
        case parameter
    }
}
class CHSesame5HistoryEvent: Codable {
    public var recordID: Int32  // 事件
    public var type: UInt8  // 事件
    public var timeStamp: UInt64        // 時間戳  ex:166
    public var historyTag: Data?         // 鑰匙標籤             23bytes
    public var devicePk: String?       // 設備本地 ecc public  4bytes
    public var parameter: Data?

    required init(type: Sesame2HistoryTypeEnum ,time: UInt64, recordID: Int32, parameter:Data?=nil) {
        self.type = type.rawValue
        self.timeStamp = time
        self.recordID = recordID
        self.parameter = parameter
    }

    required convenience init(type: Sesame2HistoryTypeEnum ,time: UInt64, recordID: Int32, content: Data,parameter:Data? = nil) {
        self.init(type: type ,time: time, recordID: recordID,parameter:parameter)

        switch type {
        case .BLE_LOCK, .WM2_LOCK, .WEB_LOCK, .BLE_CLICK, .WM2_CLICK, .WEB_CLICK, .MANUAL_CLICK,.BLE_UNLOCK, .WM2_UNLOCK, .WEB_UNLOCK:
            self.historyTag = content.copyData.toCutedHistag()
        case .NONE:
            break
        case .AUTOLOCK:
            break
        case .MANUAL_LOCKED:
            break
        case .MANUAL_UNLOCKED:
            break
        case .MANUAL_ELSE:
            break
        case .DRIVE_LOCKED:
            break
        case .DRIVE_UNLOCKED:
            break
        case .DRIVE_CLICK:
            break
        case .DRIVE_FAILED:
            break
        }
    }

    enum CodingKeys : String, CodingKey {
        case recordID
        case type
        case timeStamp
        case historyTag
        case devicePk
        case parameter
    }
}
