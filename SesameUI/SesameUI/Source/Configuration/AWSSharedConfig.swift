//
//  PrivateAWSConfig.swift
//  SesameUI
//
//  Created by frey Mac on 2025/7/18.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

#if os(iOS)
import SesameSDK
#else
import SesameWatchKitSDK
#endif

struct AWSSharedConfig: AWSConfigurable {
    let apiKey = "iGgXj9GorS4PeH90mAysg1l7kdvoIPxM25mPFl3k"
    let clientId = "ap-northeast-1:0a1820f1-dbb3-4bca-9227-2a92f6abf0ae"
    let iotEndpoint = "https://d06107753ay3c67v7y9pa-ats.iot.ap-northeast-1.amazonaws.com"
}
