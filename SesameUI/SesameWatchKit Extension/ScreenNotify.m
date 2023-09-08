//
//  Notify.m
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2021/09/06.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScreenNotify.h"
#include <notify.h>

BOOL isScreenOff(void) {
    uint64_t state;
    int token;
    
    notify_register_check("com.apple.iokit.hid.displayStatus", &token);
    notify_get_state(token, &state);
    notify_cancel(token);
    BOOL screenIsBlack = !state;
    return screenIsBlack;
}
