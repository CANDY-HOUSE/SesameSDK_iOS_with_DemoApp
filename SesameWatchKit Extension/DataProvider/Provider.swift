//
//  Provider.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/6/6.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import Combine

/// Any subject provide.
protocol Provider {
    associatedtype Subject: ProviderSubject
    /// DeviceModels publisher
    var subjectPublisher: PassthroughSubject<Subject, Error> { get }
    
    /// Start emit values
    func connect()
}

/// Any subject warpper.
/// Give any type of input and then generate any type of output.
protocol ProviderSubject {
    associatedtype Input
    associatedtype Output
    var request: CurrentValueSubject<Input, Error> { get }
    var result: PassthroughSubject<Output, Error> { get }
}
