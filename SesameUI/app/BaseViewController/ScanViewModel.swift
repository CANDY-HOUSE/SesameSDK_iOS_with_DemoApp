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
    func receivedSesame2()
}

final class ScanViewModel: ViewModel {
    private(set) var retrieveQRCodeButtonTitle = "Retrieve QRCode from photo"
    var statusUpdated: ViewStatusHandler?
    var delegate: ScanViewModelDelegate?
    
    func receivedQRCode(_ qrCodeURL: String?) {
        guard let urlString = qrCodeURL,
            let scanSchema = URL(string: urlString),
            let sesame2Key = scanSchema.sesame2Key() else {
                let error = NSError(domain: "", code: 0, userInfo: ["error message": "Parse qr code url failed"])
                statusUpdated?(.finished(.failure(error)))
                return
        }
        
        let encodedHistoryTag = "のび太".data(using: .utf8)!
        
        let tokenFetchLock = DispatchGroup()
        
        CHDeviceManager.shared.receiveSesame2Keys(sesame2Keys: [sesame2Key]) { result in
            switch result {
            case .success(let sesame2):

                for sesame2 in sesame2.data {
                    tokenFetchLock.enter()
                    Sesame2Store.shared.deletePropertyAndHisotryForDevice(sesame2)
                    sesame2.setHistoryTag(encodedHistoryTag) {_ in
                        tokenFetchLock.leave()
                    }
                }

                tokenFetchLock.wait()
                self.delegate?.receivedSesame2()
            case .failure(let error):
                self.statusUpdated?(.finished(.failure(error)))
            }
        }
    }
    
    func receivedSesame2() {
        delegate?.receivedSesame2()
    }
}
