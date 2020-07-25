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

public protocol Sesame2HistoryViewModelDelegate {
    func rightButtonTappedWithSesame2(_ sesame2: CHSesame2)
}

public final class Sesame2HistoryViewModel: ViewModel {
    private(set) var hasMoreData = true
    private let pageLength = 50
    private var requestPage = -1
    private let sesame2Busy = 7
    var delegate: Sesame2HistoryViewModelDelegate?
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
            switch  result{
            case.success(let histories):
                if histories.data.count == 0 {
                    strongSelf.hasMoreData = false
                    strongSelf.statusUpdated?(.finished(.success(true)))
                    L.d("!@# No more old data")
                }
                let storedRecordIDs = Sesame2Store.shared.getHistoriesForDevice(strongSelf.sesame2)?.map { $0.recordID }
                var historiesForStore = [CHSesame2History]()
                histories.data.forEach{ history in
                    switch history {
                    case .manualElse(let data):
                        if storedRecordIDs?.contains(data.recordID) == false {
                            historiesForStore.append(history)
                        }
                    case .manualLocked(let data):
                        if storedRecordIDs?.contains(data.recordID) == false {
                            historiesForStore.append(history)
                        }
                    case .manualUnlocked(let data):
                        if storedRecordIDs?.contains(data.recordID) == false {
                            historiesForStore.append(history)
                        }
                    case .bleLock(let data):
                        if storedRecordIDs?.contains(data.recordID) == false {
                            historiesForStore.append(history)
                        }
                    case .bleUnLock(let data):
                        if storedRecordIDs?.contains(data.recordID) == false {
                            historiesForStore.append(history)
                        }
                    case .autoLock(let data):
                        if storedRecordIDs?.contains(data.recordID) == false {
                            historiesForStore.append(history)
                        }
                    case .autoLockUpdated(let data):
                        if storedRecordIDs?.contains(data.recordID) == false {
                            historiesForStore.append(history)
                        }
                    case .mechSettingUpdated(let data):
                        if storedRecordIDs?.contains(data.recordID) == false {
                            historiesForStore.append(history)
                        }
                    case .timeChanged(let data):
                        if storedRecordIDs?.contains(data.recordID) == false {
                            historiesForStore.append(history)
                        }
                    }
                }
                
                Sesame2Store.shared.addHistories(historiesForStore, toDevice: strongSelf.sesame2)
                if strongSelf.fetchedResultsController.managedObjectContext.hasChanges {
                    try? strongSelf.fetchedResultsController.managedObjectContext.save()
                    L.d("!@# 2. Histories in DB: \(Sesame2Store.shared.getHistoriesForDevice(strongSelf.sesame2)?.map {$0.recordID} ?? [])")
                } else {
                    strongSelf.statusUpdated?(.finished(.success(true)))
                    L.d("!@# 2. Histories in DB: \(Sesame2Store.shared.getHistoriesForDevice(strongSelf.sesame2)?.map {$0.recordID} ?? [])")
                }

            case .failure(let error):
                L.d("!!!!!error",error)
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

extension Sesame2HistoryViewModel: CHSesame2Delegate {
    
    public func onBleDeviceStatusChanged(device: CHSesame2,
                                         status: CHSesame2Status) {
        if status == .receiveBle {
            device.connect(){_ in}
        }
        statusUpdated?(.received)
    }
    
    public func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        statusUpdated?(.received)
    }
}
