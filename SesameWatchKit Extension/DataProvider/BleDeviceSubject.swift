//
//  BleDeviceSubject.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/6/8.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import Combine
import SesameWatchKitSDK

final class BleDeviceSubject: ProviderSubject {
    let request: CurrentValueSubject<CHSesame2, Error>
    var result: PassthroughSubject = PassthroughSubject<CHSesame2, Error>()
    
    private var disposables = Set<AnyCancellable>()
    
    /// Create a
    /// - Parameter request: `CHSesameBleInterface` subject
    init(request: CurrentValueSubject<CHSesame2, Error>) {
        self.request = request
        self.setup()
    }
    
    /// Start emit values.
    func connect() {
        let devices = request.value
        request.send(devices)
    }
    
    private func setup() {
        request
            .sink(receiveCompletion: { [weak self] subject in
                guard let strongSelf = self else { return }
                switch subject {
                case .finished:
                    break
                case .failure(let error):
                    strongSelf.result.send(completion: .failure(error))
                }
            }) { [weak self] device in
                guard let strongSelf = self else { return }
                strongSelf.result.send(device)
        }
        .store(in: &disposables)
    }
}
