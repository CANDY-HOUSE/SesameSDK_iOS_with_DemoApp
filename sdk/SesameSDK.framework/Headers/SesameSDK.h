//
//  SesameSDK.h
//  SesameSDK
//
//  Created by Cerberus on 2019/09/04.
//  Copyright © 2019 Cerberus. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for SesameSDK.
FOUNDATION_EXPORT double SesameSDKVersionNumber;

//! Project version string for SesameSDK.
FOUNDATION_EXPORT const unsigned char SesameSDKVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <SesameSDK/PublicHeader.h>

#ifndef c_to_swift_h
#define c_to_swift_h


// AES-CMAC
void aes_cmac(unsigned char* in, unsigned int length, unsigned char* out, unsigned char* key);


// AES-CCM
#include "aes_cmac.h"


void aesCMAC(const uint8_t *message, unsigned int len, uint8_t *out, const uint8_t *key);

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
