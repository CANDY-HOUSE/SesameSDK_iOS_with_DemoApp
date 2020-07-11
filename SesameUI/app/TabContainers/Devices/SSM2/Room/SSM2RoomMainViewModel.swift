//
//  SSM2RoomMainViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/18.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
import CoreBluetooth
import UIKit.UIColor
import CoreData

public protocol SSM2RoomMainViewModelDelegate {
    func rightButtonTappedWithSSM(_ ssm: CHSesame2)
}

public final class SSM2RoomMainViewModel: ViewModel {
    var canRefresh = true
    var noMoreOldData = false
    private var pageLength = 50
    private var requestPage = -1
    var delegate: SSM2RoomMainViewModelDelegate?
    var ssm: CHSesame2
    lazy private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        SSMStore.shared.FRCOfSSMHistory(ssm, batchSize: pageLength)
    }()

    var title: String {
        let device = SSMStore.shared.getPropertyForDevice(ssm)
        return device.name ?? device.deviceID!.uuidString
    }
    
    public var statusUpdated: ViewStatusHandler?
    
    init(ssm: CHSesame2) {
        self.ssm = ssm
        ssm.connect(){_ in}
    }
    
    public func viewWillAppear() {
        ssm.delegate = self
    }
    
    public func setFetchedResultsControllerDelegate(_ delegate: NSFetchedResultsControllerDelegate) {
        fetchedResultsController.delegate = delegate
        try? fetchedResultsController.performFetch()
    }
    
    public func pullDown() {
        guard canRefresh == true else {
            statusUpdated?(.finished(.success(true)))
            return
        }
        canRefresh = false
        requestPage += 1
        getHistory(requestPage: requestPage)
    }
    
    public func getHistory(requestPage: Int) {
        guard noMoreOldData == false else {
            L.d("!@# No more old data")
            statusUpdated?(.finished(.success(true)))
            canRefresh = true
            return
        }
        
        L.d("!@# 1. Retrieve history of page: \(requestPage) with pageLength: \(pageLength)")
        ssm.getHistorys(page: UInt(requestPage), pageLength: UInt(pageLength)) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let historys):
                
                L.d("!@# 2. Historys from server or ssm: \(historys.data.map { $0.recordID })")
                if historys.data.count == 0 {
                    strongSelf.noMoreOldData = true
                    strongSelf.statusUpdated?(.finished(.success(true)))
                    strongSelf.canRefresh = true
                    L.d("!@# No more old data")
                }
                let dbHistorys = SSMStore.shared.getHistoryForDevice(strongSelf.ssm)
                
                // Clear history if history is outdated
                L.d("!@# 3. enable count from DB: \(dbHistorys?.first?.enableCount ?? 0)")
                L.d("!@# 4. enable count from server: \(historys.data.first?.enableCount ?? 0)")
                if let dbEnableCount = dbHistorys?.first?.enableCount,
                    let serverEnableCount = historys.data.first?.enableCount,
                    serverEnableCount != dbEnableCount {
                    L.d("Delete old historys in DB: \(dbHistorys?.map { $0.recordID } ?? [])")
                    SSMStore.shared.deleteHistorysForDevice(strongSelf.ssm)
                }
                
                // Make sure every history is uniqle
                let dbRecordIDs = dbHistorys?.map { $0.recordID }
                var serverRecordIDs = historys.data.map { $0.recordID }
                var duplicateRecordIDs = [Int32]()
                for serverRecordID in serverRecordIDs {
                    if dbRecordIDs?.contains(serverRecordID) == true {
                        duplicateRecordIDs.append(serverRecordID)
                        serverRecordIDs.removeAll(where: { $0 == serverRecordID })
                    }
                }
                let historysForSaving = Array(Set(serverRecordIDs)).compactMap { recordIDForSaving in
                    historys.data.first(where: { $0.recordID == recordIDForSaving })
                }
                L.d("!@# 5. Historys for saving: \(historysForSaving.map { $0.recordID })")
                L.d("!@# 6. Historys duplicated: \(duplicateRecordIDs)")
                SSMStore.shared.addHistorys(historysForSaving, toDevice: strongSelf.ssm)
                
                if strongSelf.fetchedResultsController.managedObjectContext.hasChanges {
                    try? strongSelf.fetchedResultsController.managedObjectContext.save()
                    L.d("!@# 7. Historys in DB: \(SSMStore.shared.getHistoryForDevice(strongSelf.ssm)?.map {$0.recordID} ?? [])")
                    strongSelf.canRefresh = true
                } else {
                    strongSelf.statusUpdated?(.finished(.success(true)))
                    strongSelf.canRefresh = true
                    L.d("!@# 7. Historys in DB: \(SSMStore.shared.getHistoryForDevice(strongSelf.ssm)?.map {$0.recordID} ?? [])")
                }
                
                L.d("!@# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
            case .failure(let error):
                strongSelf.statusUpdated?(.finished(.failure(error)))
                strongSelf.canRefresh = true
            }
        }
    }
    
    public var numberOfSections: Int {
        let numberOfSections = fetchedResultsController.sections?.count ?? 0
        return numberOfSections
    }
    
    public func numberOfRowsInSection(_ section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections[section].numberOfObjects
        }
        return 0
    }
    
    public func cellViewModelForIndexPath(_ indexPath: IndexPath) -> SSM2HistoryCellViewModel {
        guard let sections = fetchedResultsController.sections,
            let historys = sections[indexPath.section].objects as? [SSMHistoryMO] else {
                assertionFailure("fetchedResultsController.section error")
               return SSM2HistoryCellViewModel(history: SSMHistoryMO())
        }
        return SSM2HistoryCellViewModel(history: historys[indexPath.row])
    }
    
    public func titleForHeaderInSection(_ section: Int) -> String {
        guard let sectionInfo = fetchedResultsController.sections?[section] else {
            return ""
        }
        return sectionInfo.name
    }
    
    public func lockButtonTapped() {
        ssm.toggleWithHaptic(interval: 1.5)
    }
    
    public var lockImage: String {
        ssm.currentStatusImage()
    }
    
    public var lockColor: UIColor {
        ssm.lockColor()
    }
    
    public func rightBarButtonTapped() {
        delegate?.rightButtonTappedWithSSM(ssm)
    }
    
    public func currentDegree() -> Float? {
        guard let status = ssm.mechStatus,
            let currentAngle = status.getPosition() else {
                return nil
        }
        return angle2degree(angle: Int16(currentAngle))
    }
    
    public var isInLockRange: Bool? {
        ssm.mechStatus?.isInLockRange()
    }
    
    deinit {
//        L.d("SSM2RoomMainViewModel deinit")
    }
}

extension SSM2RoomMainViewModel: CHSesameDelegate {
    
    public func onBleDeviceStatusChanged(device: CHSesame2,
                                         status: CHSesameStatus) {
        if status == .receiveBle {
            device.connect(){_ in}
        }
        statusUpdated?(.received)
    }
    

}
