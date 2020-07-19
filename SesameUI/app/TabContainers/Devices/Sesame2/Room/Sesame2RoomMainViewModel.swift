//
//  Sesame2RoomMainViewModel.swift
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

public protocol Sesame2RoomMainViewModelDelegate {
    func rightButtonTappedWithSesame2(_ sesame2: CHSesame2)
}

public final class Sesame2RoomMainViewModel: ViewModel {
    private(set) var hasMoreData = true
    private let pageLength = 50
    private var requestPage = -1
    private let sesame2Busy = 7
    var delegate: Sesame2RoomMainViewModelDelegate?
    var sesame2: CHSesame2
    lazy private var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        Sesame2Store.shared.FRCOfSesame2History(sesame2, batchSize: pageLength)
    }()

    var title: String {
        let device = Sesame2Store.shared.getPropertyForDevice(sesame2)
        return device.name ?? device.deviceID!.uuidString
    }
    
    public var statusUpdated: ViewStatusHandler?
    
    init(sesame2: CHSesame2) {
        self.sesame2 = sesame2
        sesame2.connect(){_ in}
    }
    
    public func viewWillAppear() {
        sesame2.delegate = self
    }
    
    public func setFetchedResultsControllerDelegate(_ delegate: NSFetchedResultsControllerDelegate) {
        fetchedResultsController.delegate = delegate
        try? fetchedResultsController.performFetch()
    }
    
    public func pullDown() {
        L.d("hasMoreData??",hasMoreData)
        guard hasMoreData == true else {
            L.d("!@# No more data")
            statusUpdated?(.finished(.success(true)))
            return
        }
        
        requestPage += 1
        getHistory(requestPage: requestPage)
    }
    
    private func getHistory(requestPage: Int) {
        
        L.d("!@# 1. Retrieve history of page: \(requestPage)")
        sesame2.getHistories(page: UInt(requestPage)) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            switch result {
            case .success(let histories):
                
                L.d("!@# 2. Histories from server or sesame2: \(histories.data.map { $0.recordID })")
                if histories.data.count == 0 {
                    strongSelf.hasMoreData = false
                    strongSelf.statusUpdated?(.finished(.success(true)))
                    L.d("!@# No more old data")
                }
                
                let dbHistories = Sesame2Store.shared.getHistoriesForDevice(strongSelf.sesame2)
                
                // Clear history if history is outdated
                L.d("!@# 3. enable count from DB: \(dbHistories?.first?.registrationTimes ?? 0)")
                L.d("!@# 4. enable count from server: \(histories.data.first?.registrationTimes ?? 0)")
                if let dbEnableCount = dbHistories?.first?.registrationTimes,
                    let serverEnableCount = histories.data.first?.registrationTimes,
                    serverEnableCount != dbEnableCount {
                    L.d("Delete old histories in DB: \(dbHistories?.map { $0.recordID } ?? [])")
                    Sesame2Store.shared.deleteHistoriesForDevice(strongSelf.sesame2)
                }
                
                // Make sure every history is uniqle
                let dbRecordIDs = dbHistories?.map { $0.recordID }
                var serverRecordIDs = histories.data.map { $0.recordID }
                var duplicateRecordIDs = [Int32]()
                for serverRecordID in serverRecordIDs {
                    if dbRecordIDs?.contains(serverRecordID) == true {
                        duplicateRecordIDs.append(serverRecordID)
                        serverRecordIDs.removeAll(where: { $0 == serverRecordID })
                    }
                }
                let historiesForSaving = Array(Set(serverRecordIDs)).compactMap { recordIDForSaving in
                    histories.data.first(where: { $0.recordID == recordIDForSaving })
                }
                L.d("!@# 5. Histories for saving: \(historiesForSaving.map { $0.recordID })")
                L.d("!@# 6. Histories duplicated: \(duplicateRecordIDs)")
                Sesame2Store.shared.addHistories(historiesForSaving, toDevice: strongSelf.sesame2)
                
                if strongSelf.fetchedResultsController.managedObjectContext.hasChanges {
                    try? strongSelf.fetchedResultsController.managedObjectContext.save()
                    L.d("!@# 7. Histories in DB: \(Sesame2Store.shared.getHistoriesForDevice(strongSelf.sesame2)?.map {$0.recordID} ?? [])")
                } else {
                    strongSelf.statusUpdated?(.finished(.success(true)))
                    L.d("!@# 7. Histories in DB: \(Sesame2Store.shared.getHistoriesForDevice(strongSelf.sesame2)?.map {$0.recordID} ?? [])")
                }
                
                L.d("!@# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
            case .failure(let error):
                // todo kill the hint  if you got!!!
                // 這裡是個workaround
                // 理由:多人連線 sesame2 回 busy
                // 策略:延遲網路請求等待隔壁連上的sesame2上傳完畢後拉取

                let cmderror = error as NSError
                if cmderror.code == strongSelf.sesame2Busy {
                    L.d("策略:延遲網路請求等待隔壁連上的sesame2上傳完畢後拉取",cmderror.code)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        strongSelf.getHistory(requestPage: 0)
                    }
                } else {
                    L.d("error",error)
                    strongSelf.statusUpdated?(.finished(.failure(error)))
                }
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
    
    public func cellViewModelForIndexPath(_ indexPath: IndexPath) -> Sesame2HistoryCellViewModel {
        guard let sections = fetchedResultsController.sections,
            let histories = sections[indexPath.section].objects as? [Sesame2HistoryMO] else {
                assertionFailure("fetchedResultsController.section error")
               return Sesame2HistoryCellViewModel(history: Sesame2HistoryMO())
        }
        return Sesame2HistoryCellViewModel(history: histories[indexPath.row])
    }
    
    public func titleForHeaderInSection(_ section: Int) -> String {
        guard let sectionInfo = fetchedResultsController.sections?[section] else {
            return ""
        }
        return sectionInfo.name
    }
    
    public func cellIdentifierForIndexPath(_ indexPath: IndexPath) -> String {
        "Sesame2HistoryCell"
    }
    
    public func lockButtonTapped() {
        sesame2.toggleWithHaptic(interval: 1.5)
    }
    
    public var lockImage: String {
        sesame2.currentStatusImage()
    }
    
    public var lockColor: UIColor {
        sesame2.lockColor()
    }
    
    public func rightBarButtonTapped() {
        delegate?.rightButtonTappedWithSesame2(sesame2)
    }
    
    public func currentDegree() -> Float? {
        guard let status = sesame2.mechStatus,
            let currentAngle = status.getPosition() else {
                return nil
        }
        return angle2degree(angle: Int16(currentAngle))
    }
    
    public var isInLockRange: Bool? {
        sesame2.mechStatus?.isInLockRange()
    }
    
    deinit {
//        L.d("Sesame2RoomMainViewModel deinit")
    }
}

extension Sesame2RoomMainViewModel: CHSesame2Delegate {
    
    public func onBleDeviceStatusChanged(device: CHSesame2,
                                         status: CHSesame2Status) {
        if status == .receiveBle {
            device.connect(){_ in}
        }
        statusUpdated?(.received)
    }
    

}
