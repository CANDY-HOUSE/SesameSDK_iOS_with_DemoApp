//
//  ScanViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/7/7.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK

protocol ScanViewModelDelegate {
    func receivedSSM()
}

final class ScanViewModel: ViewModel {
    var statusUpdated: ViewStatusHandler?
    var delegate: ScanViewModelDelegate?
    
    func receivedQRCode(_ qrCodeURL: String?) {
        guard let urlString = qrCodeURL,
            let scanSchema = URL(string: urlString),
            let ssm2Key = scanSchema.ssmKey() else {
                let error = NSError(domain: "", code: 0, userInfo: ["error message": "Parse qr code url failed"])
                statusUpdated?(.finished(.failure(error)))
                return
        }
        
        let encodedHistoryTag = "のび太".data(using: .utf8)!
        
        let tokenFetchLock = DispatchGroup()
        
        CHBleManager.shared.receiveKey(ssm2Keys: [ssm2Key]) { result in
            switch result {
            case .success(let ssms):

                for ssm in ssms {
                    tokenFetchLock.enter()
                    ssm.setHistoryTag(encodedHistoryTag) {_ in
                        tokenFetchLock.leave()
                    }
                }

                tokenFetchLock.wait()
                self.delegate?.receivedSSM()
            case .failure(let error):
                self.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    func receivedSSM() {
        delegate?.receivedSSM()
    }
}
