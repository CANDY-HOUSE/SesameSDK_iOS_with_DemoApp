//
//  FirmwareZipUrlResponse.swift
//  SesameWatchKitSDK
//
//  Created by frey Mac on 2026/7/1.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import Foundation

public struct FirmwareZipUrlResponse: Codable {
    public var ok: Bool
    public var code: String?
    public var message: String?
    public var productType: Int?
    public var prefix: String?
    public var firmwareName: String?
    public var fileName: String?
    public var zipUrl: String?
    public var s3Key: String?
}
