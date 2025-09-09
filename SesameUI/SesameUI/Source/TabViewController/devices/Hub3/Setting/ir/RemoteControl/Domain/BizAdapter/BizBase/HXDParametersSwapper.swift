//
//  HXDParametersSwapper.swift
//  SesameUI
//
//  Created by wuying on 2025/9/2.
//  Copyright © 2025 CandyHouse. All rights reserved.
//
import Foundation
import SesameSDK

class HXDParametersSwapper {
    
    let tag = String(describing: HXDParametersSwapper.self)
    
    // MARK: - Power Functions
    
    func getPowerIndex(_ value: Int) -> Bool {
        return value == 0x01
    }
    
    func getPowerValue(_ isPowerOn: Bool) -> Int {
        return isPowerOn ? 0x01 : 0x00
    }
    
    // MARK: - Mode Functions
    
    func getModeIndex(_ value: Int) -> Int {
        switch value {
        case 0x01:
            return 0
        case 0x02:
            return 1
        case 0x03:
            return 2
        case 0x04:
            return 3
        case 0x05:
            return 4
        default:
            return 0
        }
    }
    
    func getModeValue(_ index: Int) -> Int {
        switch index {
        case 0:
            return 0x01 // 自动
        case 1:
            return 0x02 // 制冷
        case 2:
            return 0x03 // 抽湿
        case 3:
            return 0x04 // 送风
        case 4:
            return 0x05 // 制热
        default:
            return 0x01 // 默认制冷
        }
    }
    
    // MARK: - Fan Speed Functions
    
    func getFanSpeedIndex(_ value: Int) -> Int {
        switch value {
        case 0x01:
            return 0
        case 0x02:
            return 1
        case 0x03:
            return 2
        case 0x04:
            return 3
        default:
            return 0
        }
    }
    
    func getFanSpeedValue(_ index: Int) -> Int {
        switch index {
        case 0:
            return 0x01 // 自动
        case 1:
            return 0x02 // 低
        case 2:
            return 0x03 // 中
        case 3:
            return 0x04 // 高
        default:
            return 0x01
        }
    }
    
    // MARK: - Wind Direction Functions
    
    func getWindDirectionIndex(_ value: Int) -> Int {
        switch value {
        case 0x01:
            return 0
        case 0x02:
            return 1
        case 0x03:
            return 2
        default:
            return 0
        }
    }
    
    func getWindDirectionValue(_ index: Int) -> Int {
        switch index {
        case 0:
            return 0x01 // 向上
        case 1:
            return 0x02 // 中
        case 2:
            return 0x03 // 向下
        default:
            return 0x02 // 默认02,与显示对应
        }
    }
    
    // MARK: - Auto Wind Direction Functions
    
    func getAutoWindDirectionIndex(_ value: Int) -> Int {
        switch value {
        case 0x01:
            return 0
        case 0x00:
            return 1
        default:
            return 0
        }
    }
    
    func getAutoWindDirectionValue(_ index: Int) -> Int {
        switch index {
        case 0:
            return 0x01 // 打开
        case 1:
            return 0x00 // 关闭
        default:
            return 0x01
        }
    }
    
    /**
     * 获取当前按键指令
     * x01//电源
     * 0x02//模式
     * 0x03//风量
     * 0x04//手动风向
     * 0x05//自动风向
     * 0x06//温度加
     * 0x07//温度减
     * 表示当前按下的是哪个键
     */
    func getAirKey(_ type: ItemType) -> Int {
        switch type {
        case .powerStatusOn:
            return 0x01
        case .powerStatusOff:
            return 0x01
        case .tempControlAdd:
            return 0x06
        case .tempControlReduce:
            return 0x07
        case .mode:
            return 0x02
        case .fanSpeed:
            return 0x03
        case .windDirection:
            return 0x04
        case .autoWindDirection:
            return 0x05
        default:
            print("\(tag) Unknown item type")
            return 0x01
        }
    }
    
    /**
     * /*         开灯            关灯                亮度+            亮度-            模式            设置            定时+            定时-          色温+            色温-            1            2            3            4            5            6            A            B            C            D*/
     * {0x1d,0x2c,0x25,0x2f,0x26,0x2a,0x23,0x2b,0x22,0x80,0xb9,0x82,0xbb,0xff,0x00,0xff,0x00,0x8b,0xb2,0x8a,0xb3,0xff,0x00,0xff,0x00,0xff,0x00,0xff,0x00,0xff,0x00,0xff,0x00,0xff,0x00,0xff,0x00,0xff,0x00,0xff,0x00,0xff,0x00,0x2c,0x52,0x09,0x00},
     *  POWER_STATUS_ON = 0x01,
     *  MODE = 0x05,
     *  POWER_STATUS_OFF = 0x02,
     *  BRIGHTNESS_UP = 0x03,
     *  BRIGHTNESS_DOWN = 0x04,
     *  COLOR_TEMP_UP = 0x09,
     *  COLOR_TEMP_DOWN = 0x0A,
     */
    func getLightKey(_ type: ItemType) -> Int {
        switch type {
        case .powerStatusOn:
            return 0x01
        case .powerStatusOff:
            return 0x02
        case .mode:
            return 0x05
        case .brightnessUp:
            return 0x03
        case .brightnessDown:
            return 0x04
        case .colorTempUp:
            return 0x09
        case .colorTempDown:
            return 0x0A
        default:
            print("\(tag) Unknown item type")
            return 0x01
        }
    }
    
    /**
    KEY_TV_VOLUME_OUT =  0x01,// vol-
    KEY_TV_CHANNEL_IN =  0x02,// ch+
    KEY_TV_MENU =  0x03,// menu
    KEY_TV_CHANNEL_OUT =  0x04,// ch-
    KEY_TV_VOLUME_IN =  0x05,// vol+
    KEY_TV_POWER =  0x06,// power
    KEY_TV_MUTE =  0x07,// mute
    KEY_TV_KEY1 =  0x08,// 1 2 3 4 5 6 7 8 9
    KEY_TV_KEY2 =  0x09,
    KEY_TV_KEY3 =  0x0A,
    KEY_TV_KEY4 =  0x0B,
    KEY_TV_KEY5 =  0x0C,
    KEY_TV_KEY6 =  0x0D,
    KEY_TV_KEY7 =  0x0E,
    KEY_TV_KEY8 =  0x0F,
    KEY_TV_KEY9 =  0x10,
    KEY_TV_SELECT =  0x11,// -/--
    KEY_TV_KEY0 =  0x12,// 0
    KEY_TV_AV_TV =  0x13,// AV/TV
    KEY_TV_BACK =  0x14,// back
    KEY_TV_OK =  0x15,// ok
    KEY_TV_UP =  0x16,// up
    KEY_TV_LEFT =  0x17,// left
    KEY_TV_RIGHT =  0x18,// right
    KEY_TV_DOWN =  0x19,// down
    KEY_TV_HOME =  0x1A,// home
     */
    func getTVKey(_ type: ItemType) -> Int {
        switch type {
        case .powerStatusOn:
            return 0x06
        case .powerStatusOff:
            return 0x06
        case .mute:
            return 0x07
        case .back:
            return 0x14
        case .up:
            return 0x16
        case .menu:
            return 0x03
        case .left:
            return 0x17
        case .ok:
            return 0x15
        case .right:
            return 0x18
        case .volumeUp:
            return 0x05
        case .down:
            return 0x19
        case .channelUp:
            return 0x02
        case .volumeDown:
            return 0x01
        case .home:
            return 0x1A
        case .channelDown:
            return 0x04
        default:
            print("\(tag) Unknown item type")
            return 0x01
        }
    }
}
