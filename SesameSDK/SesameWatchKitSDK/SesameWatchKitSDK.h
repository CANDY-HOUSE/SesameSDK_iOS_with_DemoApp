//
//  SesameWatchKitSDK.h
//  SesameWatchKitSDK
//
//  Created by YuHan Hsiao on 2020/6/1.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWSTask.h"
#import "AWSService.h"
#import "AWSCategory.h"
#import "AWSInfo.h"
#import "AWSTaskCompletionSource.h"
#import "AWSCognitoIdentityModel.h"
#import "AWSCognitoIdentity.h"
#import "AWSAPIGatewayModel.h"
#import "AWSAPIGatewayClient.h"
#import "AWSServiceEnum.h"
#import "AWSCancellationToken.h"
#import "AWSCancellationTokenRegistration.h"
#import "AWSNetworking.h"
#import "AWSGeneric.h"
#import "AWSCredentialsProvider.h"
#import "AWSModel.h"
#import "AWSMantle.h"
#import "AWSCognitoIdentityResources.h"
#import "AWSIdentityProvider.h"
#import "AWSMTLJSONAdapter.h"
#import "AWSMTLManagedObjectAdapter.h"
#import "AWSMTLModel.h"
#import "AWSMTLModel+NSCoding.h"
#import "AWSMTLValueTransformer.h"
#import "NSArray+AWSMTLManipulationAdditions.h"
#import "NSDictionary+AWSMTLManipulationAdditions.h"
#import "NSObject+AWSMTLComparisonAdditions.h"
#import "NSValueTransformer+AWSMTLInversionAdditions.h"
#import "NSValueTransformer+AWSMTLPredefinedTransformerAdditions.h"
#import "AWSSignature.h"
#import "AWSAPIGateway.h"

#ifndef c_to_swift_h
#define c_to_swift_h

int aes_ccm_ae(const uint8_t *key, size_t key_len,
               const uint8_t *nonce, size_t M,
               const uint8_t *plain, size_t plain_len,
               const uint8_t *aad, size_t aad_len,
               uint8_t *crypt, uint8_t *auth);

int aes_ccm_ad(const uint8_t *key, size_t key_len,
               const uint8_t *nonce, size_t M,
               const uint8_t *crypt, size_t crypt_len,
               const uint8_t *aad, size_t aad_len,
               const uint8_t *auth, uint8_t *plain);

#endif /* c_to_swift_h */

