//
//  IRDeviceType.swift
//  SesameUI
//
//  Created by eddy on 2024/6/7.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation

public struct IRDeviceType {
    /// 電視
    public static let DEVICE_REMOTE_TV = 0x2000
    /// 機上盒
    public static let DEVICE_REMOTE_STB = 0x4000
    /// 影碟機
    public static let DEVICE_REMOTE_DVD = 0x6000
    /// 風扇
    public static let DEVICE_REMOTE_FANS = 0x8000
    /// 投影機
    public static let DEVICE_REMOTE_PJT = 0xA000
    /// 空調
    public static let DEVICE_REMOTE_AIR = 0xC000
    /// 遙控燈
    public static let DEVICE_REMOTE_LIGHT = 0xE000
    /// IPTV
    public static let DEVICE_REMOTE_IPTV = 0x2100
    /// 數位相機
    public static let DEVICE_REMOTE_DC = 0x2300
    
    public static let DEVICE_REMOTE_BOX = 0x2500
    /// 空氣淨化器
    public static let DEVICE_REMOTE_AP = 0x2700
    /// 音響
    public static let DEVICE_REMOTE_AUDIO = 0x2900
    public static let DEVICE_REMOTE_POWER = 0x2B00
    public static let DEVICE_REMOTE_SLR = 0x2D00
    /// 熱水器
    public static let DEVICE_REMOTE_HW = 0x2F00
    public static let DEVICE_REMOTE_ROBOT = 0x3100
    public static let DEVICE_REMOTE_CUSTOM = 0xFE00
//    static let DEVICE_ADD = 0xFF000000
    
//    static let DEVICE_REMOTE_TV_EX = 0x2000 | 0x10000
//    static let DEVICE_REMOTE_STB_EX = 0x4000 | 0x10000
//    static let DEVICE_REMOTE_DVD_EX = 0x6000 | 0x10000
//    static let DEVICE_REMOTE_FANS_EX = 0x8000 | 0x10000
//    static let DEVICE_REMOTE_PJT_EX = 0xA000 | 0x10000
//    static let DEVICE_REMOTE_AIR_EX = 0xC000 | 0x10000
//    static let DEVICE_REMOTE_LIGHT_EX = 0xE000 | 0x10000
//    static let DEVICE_REMOTE_IPTV_EX = 0x2100 | 0x10000
//    static let DEVICE_REMOTE_DC_EX = 0x2300 | 0x10000
//    static let DEVICE_REMOTE_BOX_EX = 0x2500 | 0x10000
//    static let DEVICE_REMOTE_AP_EX = 0x2700 | 0x10000
//    static let DEVICE_REMOTE_AUDIO_EX = 0x2900 | 0x10000
//    static let DEVICE_REMOTE_POWER_EX = 0x2B00 | 0x10000
//    static let DEVICE_REMOTE_SLR_EX = 0x2D00 | 0x10000
//    static let DEVICE_REMOTE_HW_EX = 0x2F00 | 0x10000
//    static let DEVICE_REMOTE_CUSTOM_EX = 0xFE000000 | 0x10000
//    
//    public struct REMOTE_KEY_TV_EX {
//        static let KEY_COUNT = 1
//        static let KEY_TV_HOME_EX = DEVICE_REMOTE_TV_EX | 0x01
//    }
//    
//    public struct REMOTE_KEY_IPTV_EX {
//        static let KEY_COUNT = 1
//        static let KEY_IPTV_HOME_EX = DEVICE_REMOTE_IPTV_EX | 0x01
//    }
//    
//    public struct REMOTE_KEY_AIR_EX {
//        static let KEY_COUNT = 1
//        static let KEY_AIR_HOME_EX = DEVICE_REMOTE_IPTV_EX | 0x01
//    }
    
    public struct REMOTE_KEY_TV {
        static let KEY_COUNT = 26
        static let KEY_TV_VOLUME_OUT = DEVICE_REMOTE_TV | 0x01
        static let KEY_TV_CHANNEL_IN = DEVICE_REMOTE_TV | 0x03
        static let KEY_TV_MENU = DEVICE_REMOTE_TV | 0x05
        static let KEY_TV_CHANNEL_OUT = DEVICE_REMOTE_TV | 0x07
        static let KEY_TV_VOLUME_IN = DEVICE_REMOTE_TV | 0x09
        static let KEY_TV_POWER = DEVICE_REMOTE_TV | 0x0B
        static let KEY_TV_MUTE = DEVICE_REMOTE_TV | 0x0D
        static let KEY_TV_KEY1 = DEVICE_REMOTE_TV | 0x0F
        static let KEY_TV_KEY2 = DEVICE_REMOTE_TV | 0x11
        static let KEY_TV_KEY3 = DEVICE_REMOTE_TV | 0x13
        static let KEY_TV_KEY4 = DEVICE_REMOTE_TV | 0x15
        static let KEY_TV_KEY5 = DEVICE_REMOTE_TV | 0x17
        static let KEY_TV_KEY6 = DEVICE_REMOTE_TV | 0x19
        static let KEY_TV_KEY7 = DEVICE_REMOTE_TV | 0x1B
        static let KEY_TV_KEY8 = DEVICE_REMOTE_TV | 0x1D
        static let KEY_TV_KEY9 = DEVICE_REMOTE_TV | 0x1F
        static let KEY_TV_SELECT = DEVICE_REMOTE_TV | 0x21
        static let KEY_TV_KEY0 = DEVICE_REMOTE_TV | 0x23
        static let KEY_TV_AV_TV = DEVICE_REMOTE_TV | 0x25
        static let KEY_TV_BACK = DEVICE_REMOTE_TV | 0x27
        static let KEY_TV_OK = DEVICE_REMOTE_TV | 0x29
        static let KEY_TV_UP = DEVICE_REMOTE_TV | 0x2B
        static let KEY_TV_LEFT = DEVICE_REMOTE_TV | 0x2D
        static let KEY_TV_RIGHT = DEVICE_REMOTE_TV | 0x2F
        static let KEY_TV_DOWN = DEVICE_REMOTE_TV | 0x31
        static let KEY_TV_HOME = DEVICE_REMOTE_TV | 0x33
    }
    
    public struct REMOTE_KEY_STB {
        static let KEY_COUNT = 23
        static let KEY_STB_AWAIT = DEVICE_REMOTE_STB | 0x01
        static let KEY_STB_KEY1 = DEVICE_REMOTE_STB | 0x03
        static let KEY_STB_KEY2 = DEVICE_REMOTE_STB | 0x05
        static let KEY_STB_KEY3 = DEVICE_REMOTE_STB | 0x07
        static let KEY_STB_KEY4 = DEVICE_REMOTE_STB | 0x09
        static let KEY_STB_KEY5 = DEVICE_REMOTE_STB | 0x0B
        static let KEY_STB_KEY6 = DEVICE_REMOTE_STB | 0x0D
        static let KEY_STB_KEY7 = DEVICE_REMOTE_STB | 0x0F
        static let KEY_STB_KEY8 = DEVICE_REMOTE_STB | 0x11
        static let KEY_STB_KEY9 = DEVICE_REMOTE_STB | 0x13
        static let KEY_STB_GUIDE = DEVICE_REMOTE_STB | 0x15
        static let KEY_STB_KEY0 = DEVICE_REMOTE_STB | 0x17
        static let KEY_STB_BACK = DEVICE_REMOTE_STB | 0x19
        static let KEY_STB_UP = DEVICE_REMOTE_STB | 0x1B
        static let KEY_STB_LEFT = DEVICE_REMOTE_STB | 0x1D
        static let KEY_STB_OK = DEVICE_REMOTE_STB | 0x1F
        static let KEY_STB_RIGHT = DEVICE_REMOTE_STB | 0x21
        static let KEY_STB_DOWN = DEVICE_REMOTE_STB | 0x23
        static let KEY_STB_VOLUME_IN = DEVICE_REMOTE_STB | 0x25
        static let KEY_STB_VOLUME_OUT = DEVICE_REMOTE_STB | 0x27
        static let KEY_STB_CHANNEL_IN = DEVICE_REMOTE_STB | 0x29
        static let KEY_STB_CHANNEL_OUT = DEVICE_REMOTE_STB | 0x2B
        static let KEY_STB_MENU = DEVICE_REMOTE_STB | 0x2D
    }
    
    public struct REMOTE_KEY_DVD {
        static let KEY_COUNT = 19
        static let KEY_DVD_LEFT = DEVICE_REMOTE_DVD | 0x01
        static let KEY_DVD_UP = DEVICE_REMOTE_DVD | 0x03
        static let KEY_DVD_OK = DEVICE_REMOTE_DVD | 0x05
        static let KEY_DVD_DOWN = DEVICE_REMOTE_DVD | 0x07
        static let KEY_DVD_RIGHT = DEVICE_REMOTE_DVD | 0x09
        static let KEY_DVD_POWER = DEVICE_REMOTE_DVD | 0x0B
        static let KEY_DVD_MUTE = DEVICE_REMOTE_DVD | 0x0D
        static let KEY_DVD_FAST_BACK = DEVICE_REMOTE_DVD | 0x0F
        static let KEY_DVD_PLAY = DEVICE_REMOTE_DVD | 0x11
        static let KEY_DVD_FAST_FORWARD = DEVICE_REMOTE_DVD | 0x13
        static let KEY_DVD_UP_SONG = DEVICE_REMOTE_DVD | 0x15
        static let KEY_DVD_STOP = DEVICE_REMOTE_DVD | 0x17
        static let KEY_DVD_NEXT_SONG = DEVICE_REMOTE_DVD | 0x19
        static let KEY_DVD_STANDARD = DEVICE_REMOTE_DVD | 0x1B
        static let KEY_DVD_PAUSE = DEVICE_REMOTE_DVD | 0x1D
        static let KEY_DVD_TITLE = DEVICE_REMOTE_DVD | 0x1F
        static let KEY_DVD_OC = DEVICE_REMOTE_DVD | 0x21
        static let KEY_DVD_MENU = DEVICE_REMOTE_DVD | 0x23
        static let KEY_DVD_BACK = DEVICE_REMOTE_DVD | 0x25
    }
    
    public struct REMOTE_KEY_FANS {
        static let KEY_COUNT = 22
        static let KEY_FANS_POWER = DEVICE_REMOTE_FANS | 0x01
        static let KEY_FANS_WIND_SPEED = DEVICE_REMOTE_FANS | 0x03
        static let KEY_FANS_SHAKE_HEAD = DEVICE_REMOTE_FANS | 0x05
        static let KEY_FANS_MODE = DEVICE_REMOTE_FANS | 0x07
        static let KEY_FANS_TIMER = DEVICE_REMOTE_FANS | 0x09
        static let KEY_FANS_LIGHT = DEVICE_REMOTE_FANS | 0x0B
        static let KEY_FANS_ANION = DEVICE_REMOTE_FANS | 0x0D
        static let KEY_FANS_KEY1 = DEVICE_REMOTE_FANS | 0x0F
        static let KEY_FANS_KEY2 = DEVICE_REMOTE_FANS | 0x11
        static let KEY_FANS_KEY3 = DEVICE_REMOTE_FANS | 0x13
        static let KEY_FANS_KEY4 = DEVICE_REMOTE_FANS | 0x15
        static let KEY_FANS_KEY5 = DEVICE_REMOTE_FANS | 0x17
        static let KEY_FANS_KEY6 = DEVICE_REMOTE_FANS | 0x19
        static let KEY_FANS_KEY7 = DEVICE_REMOTE_FANS | 0x1B
        static let KEY_FANS_KEY8 = DEVICE_REMOTE_FANS | 0x1D
        static let KEY_FANS_KEY9 = DEVICE_REMOTE_FANS | 0x1F
        static let KEY_FANS_SLEEP = DEVICE_REMOTE_FANS | 0x21
        static let KEY_FANS_COOL = DEVICE_REMOTE_FANS | 0x23
        static let KEY_FANS_AIR_RATE = DEVICE_REMOTE_FANS | 0x25
        static let KEY_FANS_AIR_RATE_LOW = DEVICE_REMOTE_FANS | 0x27
        static let KEY_FANS_AIR_RATE_MIDDLE = DEVICE_REMOTE_FANS | 0x29
        static let KEY_FANS_AIR_RATE_HIGH = DEVICE_REMOTE_FANS | 0x2B
    }
    
    public struct REMOTE_KEY_PJT {
        static let KEY_COUNT = 22
        static let KEY_PJT_POWER_ON = DEVICE_REMOTE_PJT | 0x01
        static let KEY_PJT_POWER_OFF = DEVICE_REMOTE_PJT | 0x03
        static let KEY_PJT_COMPUTER = DEVICE_REMOTE_PJT | 0x05
        static let KEY_PJT_VIDEO = DEVICE_REMOTE_PJT | 0x07
        static let KEY_PJT_SIGNAL = DEVICE_REMOTE_PJT | 0x09
        static let KEY_PJT_ZOOM_IN = DEVICE_REMOTE_PJT | 0x0B
        static let KEY_PJT_ZOOM_OUT = DEVICE_REMOTE_PJT | 0x0D
        static let KEY_PJT_PICTURE_IN = DEVICE_REMOTE_PJT | 0x0F
        static let KEY_PJT_PICTURE_OUT = DEVICE_REMOTE_PJT | 0x11
        static let KEY_PJT_MENU = DEVICE_REMOTE_PJT | 0x13
        static let KEY_PJT_OK = DEVICE_REMOTE_PJT | 0x15
        static let KEY_PJT_UP = DEVICE_REMOTE_PJT | 0x17
        static let KEY_PJT_LEFT = DEVICE_REMOTE_PJT | 0x19
        static let KEY_PJT_RIGHT = DEVICE_REMOTE_PJT | 0x1B
        static let KEY_PJT_DOWN = DEVICE_REMOTE_PJT | 0x1D
        static let KEY_PJT_EXIT = DEVICE_REMOTE_PJT | 0x1F
        static let KEY_PJT_VOLUME_IN = DEVICE_REMOTE_PJT | 0x21
        static let KEY_PJT_VOLUME_OUT = DEVICE_REMOTE_PJT | 0x23
        static let KEY_PJT_MUTE = DEVICE_REMOTE_PJT | 0x25
        static let KEY_PJT_AUTOMATIC = DEVICE_REMOTE_PJT | 0x27
        static let KEY_PJT_PAUSE = DEVICE_REMOTE_PJT | 0x29
        static let KEY_PJT_BRIGHTNESS = DEVICE_REMOTE_PJT | 0x2B
    }
    
    public struct REMOTE_KEY_AIR {
        static let KEY_COUNT = 18
        static let KEY_AIR_POWER = DEVICE_REMOTE_AIR | 0x01
        static let KEY_AIR_MODE = DEVICE_REMOTE_AIR | 0x03
        static let KEY_AIR_WIND_RATE = DEVICE_REMOTE_AIR | 0x05
        static let KEY_AIR_WIND_DIRECTION = DEVICE_REMOTE_AIR | 0x07
        static let KEY_AIR_AUTOMATIC_WIND_DIRECTION = DEVICE_REMOTE_AIR | 0x09
        static let KEY_AIR_TEMPERATURE_IN = DEVICE_REMOTE_AIR | 0x0B
        static let KEY_AIR_TEMPERATURE_OUT = DEVICE_REMOTE_AIR | 0x0D
        static let KEY_AIR_SLEEP = DEVICE_REMOTE_AIR | 0x0F
        static let KEY_AIR_HEAT = DEVICE_REMOTE_AIR | 0x11
        static let KEY_AIR_LIGHT = DEVICE_REMOTE_AIR | 0x13
        static let KEY_AIR_ECO = DEVICE_REMOTE_AIR | 0x15
        static let KEY_AIR_COOL = DEVICE_REMOTE_AIR | 0x17
        static let KEY_AIR_HOT = DEVICE_REMOTE_AIR | 0x19
        static let KEY_AIR_MUTE = DEVICE_REMOTE_AIR | 0x1B
        static let KEY_AIR_STRONG = DEVICE_REMOTE_AIR | 0x1D
        static let KEY_AIR_XX = DEVICE_REMOTE_AIR | 0x1F
        static let KEY_AIR_YY = DEVICE_REMOTE_AIR | 0x21
        static let KEY_AIR_HF = DEVICE_REMOTE_AIR | 0x23
    }
    
    public struct REMOTE_KEY_IPTV {
        static let KEY_COUNT = 25
        static let KEY_IPTV_POWER = DEVICE_REMOTE_IPTV | 0x01
        static let KEY_IPTV_MUTE = DEVICE_REMOTE_IPTV | 0x03
        static let KEY_IPTV_VOLUME_IN = DEVICE_REMOTE_IPTV | 0x05
        static let KEY_IPTV_VOLUME_OUT = DEVICE_REMOTE_IPTV | 0x07
        static let KEY_IPTV_CHANNEL_IN = DEVICE_REMOTE_IPTV | 0x09
        static let KEY_IPTV_CHANNEL_OUT = DEVICE_REMOTE_IPTV | 0x0B
        static let KEY_IPTV_UP = DEVICE_REMOTE_IPTV | 0x0D
        static let KEY_IPTV_LEFT = DEVICE_REMOTE_IPTV | 0x0F
        static let KEY_IPTV_OK = DEVICE_REMOTE_IPTV | 0x11
        static let KEY_IPTV_RIGHT = DEVICE_REMOTE_IPTV | 0x13
        static let KEY_IPTV_DOWN = DEVICE_REMOTE_IPTV | 0x15
        static let KEY_IPTV_PLAY_PAUSE = DEVICE_REMOTE_IPTV | 0x17
        static let KEY_IPTV_KEY1 = DEVICE_REMOTE_IPTV | 0x19
        static let KEY_IPTV_KEY2 = DEVICE_REMOTE_IPTV | 0x1B
        static let KEY_IPTV_KEY3 = DEVICE_REMOTE_IPTV | 0x1D
        static let KEY_IPTV_KEY4 = DEVICE_REMOTE_IPTV | 0x1F
        static let KEY_IPTV_KEY5 = DEVICE_REMOTE_IPTV | 0x21
        static let KEY_IPTV_KEY6 = DEVICE_REMOTE_IPTV | 0x23
        static let KEY_IPTV_KEY7 = DEVICE_REMOTE_IPTV | 0x25
        static let KEY_IPTV_KEY8 = DEVICE_REMOTE_IPTV | 0x27
        static let KEY_IPTV_KEY9 = DEVICE_REMOTE_IPTV | 0x29
        static let KEY_IPTV_KEY0 = DEVICE_REMOTE_IPTV | 0x2B
        static let KEY_IPTV_BACK = DEVICE_REMOTE_IPTV | 0x2D
        static let KEY_IPTV_HOME = DEVICE_REMOTE_IPTV | 0x2F
        static let KEY_IPTV_MENU = DEVICE_REMOTE_IPTV | 0x31
    }
    
    struct REMOTE_KEY_DC {
        static let KEY_COUNT = 1
        static let KEY_DC_SWITCH = DEVICE_REMOTE_DC | 0x01 // switch
    }
    
    struct REMOTE_KEY_SLR {
        static let KEY_COUNT = 1
        static let KEY_SLR_SWITCH = DEVICE_REMOTE_SLR | 0x01 // switch
    }
    
    struct REMOTE_KEY_POWER {
        static let KEY_COUNT = 6
        static let KEY_POWER_SWITCH = DEVICE_REMOTE_POWER | 0x01 // switch
        static let KEY_POWER_SPEED = DEVICE_REMOTE_POWER | 0x03 // wind speed
        static let KEY_POWER_HEAD = DEVICE_REMOTE_POWER | 0x05 // shake head
        static let KEY_POWER_MODE = DEVICE_REMOTE_POWER | 0x07 // mode
        static let KEY_POWER_TIMER = DEVICE_REMOTE_POWER | 0x09 // timer
        static let KEY_POWER_TIMER1 = DEVICE_REMOTE_POWER | 0x11
    }
    
    struct REMOTE_KEY_LIGHT {
        static let KEY_COUNT = 20
        static let KEY_LIGHT_POWER_ON = DEVICE_REMOTE_LIGHT | 0x01
        static let KEY_LIGHT_POWER_OFF = DEVICE_REMOTE_LIGHT | 0x03
        static let KEY_LIGHT_LD_UP = DEVICE_REMOTE_LIGHT | 0x05
        static let KEY_LIGHT_LD_DOWN = DEVICE_REMOTE_LIGHT | 0x07
        static let KEY_LIGHT_MODE = DEVICE_REMOTE_LIGHT | 0x09
        static let KEY_LIGHT_SET = DEVICE_REMOTE_LIGHT | 0x0B
        static let KEY_LIGHT_TIME_UP = DEVICE_REMOTE_LIGHT | 0x0D
        static let KEY_LIGHT_TIME_DOWN = DEVICE_REMOTE_LIGHT | 0x0F
        static let KEY_LIGHT_SW_UP = DEVICE_REMOTE_LIGHT | 0x11
        static let KEY_LIGHT_SW_DOWN = DEVICE_REMOTE_LIGHT | 0x13
        static let KEY_LIGHT_KEY1 = DEVICE_REMOTE_LIGHT | 0x15
        static let KEY_LIGHT_KEY2 = DEVICE_REMOTE_LIGHT | 0x17
        static let KEY_LIGHT_KEY3 = DEVICE_REMOTE_LIGHT | 0x19
        static let KEY_LIGHT_KEY4 = DEVICE_REMOTE_LIGHT | 0x1B
        static let KEY_LIGHT_KEY5 = DEVICE_REMOTE_LIGHT | 0x1D
        static let KEY_LIGHT_KEY6 = DEVICE_REMOTE_LIGHT | 0x1F
        static let KEY_LIGHT_KEYA = DEVICE_REMOTE_LIGHT | 0x21
        static let KEY_LIGHT_KEYB = DEVICE_REMOTE_LIGHT | 0x23
        static let KEY_LIGHT_KEYC = DEVICE_REMOTE_LIGHT | 0x25
        static let KEY_LIGHT_KEYD = DEVICE_REMOTE_LIGHT | 0x27
    }
    
    struct REMOTE_KEY_AP {
        static let KEY_COUNT = 18
        static let KEY_AP_POWER = DEVICE_REMOTE_AP | 0x01
        static let KEY_AP_AUTO = DEVICE_REMOTE_AP | 0x03
        static let KEY_AP_SPEED = DEVICE_REMOTE_AP | 0x05
        static let KEY_AP_TIMER = DEVICE_REMOTE_AP | 0x07
        static let KEY_AP_MODE = DEVICE_REMOTE_AP | 0x09
        static let KEY_AP_LI = DEVICE_REMOTE_AP | 0x0B
        static let KEY_AP_FEEL = DEVICE_REMOTE_AP | 0x0D
        static let KEY_AP_MUTE = DEVICE_REMOTE_AP | 0x0F
        static let KEY_AP_CLOSE_LIGHT = DEVICE_REMOTE_AP | 0x11
        static let KEY_AP_STRONG = DEVICE_REMOTE_AP | 0x13
        static let KEY_AP_NATIVE = DEVICE_REMOTE_AP | 0x15
        static let KEY_AP_CLOSE = DEVICE_REMOTE_AP | 0x17
        static let KEY_AP_SLEEP = DEVICE_REMOTE_AP | 0x19
        static let KEY_AP_SMART = DEVICE_REMOTE_AP | 0x1B
        static let KEY_AP_LIGHT1 = DEVICE_REMOTE_AP | 0x1D
        static let KEY_AP_LIGHT2 = DEVICE_REMOTE_AP | 0x1F
        static let KEY_AP_LIGHT3 = DEVICE_REMOTE_AP | 0x21
        static let KEY_AP_UV = DEVICE_REMOTE_AP | 0x23
    }
    
    struct REMOTE_KEY_HW {
        static let KEY_COUNT = 10
        static let KEY_HW_POWER = DEVICE_REMOTE_HW | 0x01
        static let KEY_HW_SET = DEVICE_REMOTE_HW | 0x03
        static let KEY_HW_TEMP_ADD = DEVICE_REMOTE_HW | 0x05
        static let KEY_HW_TEMP_SUB = DEVICE_REMOTE_HW | 0x07
        static let KEY_HW_MODE = DEVICE_REMOTE_HW | 0x09
        static let KEY_HW_OK = DEVICE_REMOTE_HW | 0x0B
        static let KEY_HW_TIMER = DEVICE_REMOTE_HW | 0x0D
        static let KEY_HW_WAIT = DEVICE_REMOTE_HW | 0x0F
        static let KEY_HW_TIME = DEVICE_REMOTE_HW | 0x11
        static let KEY_HW_SAVE_TEMP = DEVICE_REMOTE_HW | 0x13
    }
    
    struct REMOTE_KEY_AUDIO {
        static let KEY_COUNT = 18
        static let KEY_AUDIO_LEFT = DEVICE_REMOTE_AUDIO | 0x01
        static let KEY_AUDIO_UP = DEVICE_REMOTE_AUDIO | 0x03
        static let KEY_AUDIO_OK = DEVICE_REMOTE_AUDIO | 0x05
        static let KEY_AUDIO_DOWN = DEVICE_REMOTE_AUDIO | 0x07
        static let KEY_AUDIO_RIGHT = DEVICE_REMOTE_AUDIO | 0x09
        static let KEY_AUDIO_POWER = DEVICE_REMOTE_AUDIO | 0x0B
        static let KEY_AUDIO_VOLUME_IN = DEVICE_REMOTE_AUDIO | 0x0D
        static let KEY_AUDIO_VOLUME_MUTE = DEVICE_REMOTE_AUDIO | 0x0F
        static let KEY_AUDIO_VOLUME_OUT = DEVICE_REMOTE_AUDIO | 0x11
        static let KEY_AUDIO_FAST_BACK = DEVICE_REMOTE_AUDIO | 0x13
        static let KEY_AUDIO_PLAY = DEVICE_REMOTE_AUDIO | 0x15
        static let KEY_AUDIO_FAST_FORWARD = DEVICE_REMOTE_AUDIO | 0x17
        static let KEY_AUDIO_SONG_UP = DEVICE_REMOTE_AUDIO | 0x19
        static let KEY_AUDIO_STOP = DEVICE_REMOTE_AUDIO | 0x1B
        static let KEY_AUDIO_SONG_DOWN = DEVICE_REMOTE_AUDIO | 0x1D
        static let KEY_AUDIO_PAUSE = DEVICE_REMOTE_AUDIO | 0x1F
        static let KEY_AUDIO_MENU = DEVICE_REMOTE_AUDIO | 0x21
        static let KEY_AUDIO_BACK = DEVICE_REMOTE_AUDIO | 0x23
    }
    
    struct REMOTE_KEY_ROBOT {
        static let KEY_COUNT = 21
        static let KEY_ROBOT_POWER_ON = DEVICE_REMOTE_ROBOT | 0x01
        static let KEY_ROBOT_POWER_OFF = DEVICE_REMOTE_ROBOT | 0x03
        static let KEY_ROBOT_UP = DEVICE_REMOTE_ROBOT | 0x05
        static let KEY_ROBOT_DOWN = DEVICE_REMOTE_ROBOT | 0x07
        static let KEY_ROBOT_LEFT = DEVICE_REMOTE_ROBOT | 0x09
        static let KEY_ROBOT_RIGHT = DEVICE_REMOTE_ROBOT | 0x0B
        static let KEY_ROBOT_OK = DEVICE_REMOTE_ROBOT | 0x0D
        static let KEY_ROBOT_HC = DEVICE_REMOTE_ROBOT | 0x0F
        static let KEY_ROBOT_MODE = DEVICE_REMOTE_ROBOT | 0x11
        static let KEY_ROBOT_HOMEPAGE = DEVICE_REMOTE_ROBOT | 0x13
        static let KEY_ROBOT_TIME = DEVICE_REMOTE_ROBOT | 0x15
        static let KEY_ROBOT_QY = DEVICE_REMOTE_ROBOT | 0x17
        static let KEY_ROBOT_YB = DEVICE_REMOTE_ROBOT | 0x19
        static let KEY_ROBOT_JB = DEVICE_REMOTE_ROBOT | 0x1B
        static let KEY_ROBOT_AUTO = DEVICE_REMOTE_ROBOT | 0x1D
        static let KEY_ROBOT_DD = DEVICE_REMOTE_ROBOT | 0x1F
        static let KEY_ROBOT_GX = DEVICE_REMOTE_ROBOT | 0x21
        static let KEY_ROBOT_SJ = DEVICE_REMOTE_ROBOT | 0x23
        static let KEY_ROBOT_YY = DEVICE_REMOTE_ROBOT | 0x25
        static let KEY_ROBOT_SPEED = DEVICE_REMOTE_ROBOT | 0x27
        static let KEY_ROBOT_SET = DEVICE_REMOTE_ROBOT | 0x29
    }
}
