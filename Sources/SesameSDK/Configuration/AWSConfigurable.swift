//
//  AWSConfigurable.swift
//  SesameSDK
//
//  Created by frey Mac on 2025/7/18.
//

public protocol AWSConfigurable {
    var apiKey: String { get }
    var clientId: String { get }
    var iotEndpoint: String { get }
}

public class AWSConfigManager {
    public static var shared: AWSConfigurable!
    
    public static var config: AWSConfigurable {
        guard let config = shared else {
            fatalError("AWSConfig has not been configured. Please call AWSConfigManager.configure() before using.")
        }
        return config
    }
    
    public static func configure(with config: AWSConfigurable) {
        shared = config
    }
}
