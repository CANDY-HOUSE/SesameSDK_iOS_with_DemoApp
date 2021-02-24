#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AWSIoT.h"
#import "AWSIoTData.h"
#import "AWSIoTDataManager.h"
#import "AWSIoTDataModel.h"
#import "AWSIoTDataResources.h"
#import "AWSIoTDataService.h"
#import "AWSIoTManager.h"
#import "AWSIoTModel.h"
#import "AWSIoTMQTTTypes.h"
#import "AWSIoTResources.h"
#import "AWSIoTService.h"
#import "AWSMQTTDecoder.h"
#import "AWSMQTTEncoder.h"
#import "AWSMQTTMessage.h"
#import "AWSMQTTSession.h"
#import "AWSMQttTxFlow.h"
#import "AWSSRWebSocket.h"

FOUNDATION_EXPORT double AWSIoTVersionNumber;
FOUNDATION_EXPORT const unsigned char AWSIoTVersionString[];

