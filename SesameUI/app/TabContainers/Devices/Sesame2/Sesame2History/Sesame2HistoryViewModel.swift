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
        Sesame2Store.shared.FRCOfSesame2History(sesame2, offset: 0, limit: 50)
    }()

    var title: String {
        let device = Sesame2Store.shared.getPropertyForDevice(sesame2)
        return device.name ?? device.deviceID!.uuidString
    }
    
    public var statusUpdated: ViewStatusHandler?
    
    init(sesame2: CHSesame2) {
        self.sesame2 = sesame2
        sesame2.connect(){_ in}
        
        if CHConfiguration.shared.isHistoryStorageEnabled() == false {
            Sesame2Store.shared.deleteHistoriesForDevice(sesame2)
        }
    }
    
    public func viewWillAppear() {
        sesame2.delegate = self
    }
    
    public func setFetchedResultsControllerDelegate(_ delegate: NSFetchedResultsControllerDelegate) {
        fetchedResultsController.delegate = delegate
        try? fetchedResultsController.performFetch()
    }
    
    public func loadMore() {
        L.d("hasMoreData??",hasMoreData)
        guard hasMoreData == true else {
            L.d("!@# No more data")
            statusUpdated?(.finished(.success(true)))
            return
        }
        
        requestPage += 1
        getHistory(requestPage: requestPage)
    }
    
    private func historiesCount() -> Int {
        let countFetcher = Sesame2Store.shared.FRCOfSesame2History(sesame2)
        try? countFetcher.performFetch()
        return countFetcher.fetchedObjects?.count ?? 0
    }
    
    private func getHistory(requestPage: Int) {
        sesame2.getHistories(page: UInt(requestPage)) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            // Retrieve content from store
            if requestPage != 0 {
                let totalCount = strongSelf.historiesCount()
                var limit = (50 * (requestPage + 1))
                limit = limit <= totalCount ? limit : totalCount
                
                let delegate = strongSelf.fetchedResultsController.delegate
                strongSelf.fetchedResultsController = Sesame2Store.shared.FRCOfSesame2History(strongSelf.sesame2, offset: 0, limit: limit)
                strongSelf.fetchedResultsController.delegate = delegate
                try? strongSelf.fetchedResultsController.performFetch()
            }
            
            switch result{
            case.success(let histories):
                L.d("Request history page: \(requestPage), Result: \(histories.data.count) datas")
                
                if histories.data.count == 0 {
                    strongSelf.hasMoreData = false
                    strongSelf.statusUpdated?(.finished(.success(true)))
                    L.d("!@# No more old data")
                    return
                }

                var storedRecordIDs: [Int32]?
                guard let fetchedHistories = strongSelf.fetchedResultsController.fetchedObjects as? [Sesame2HistoryMO] else {
                    let error = NSError(domain: "", code: 0, userInfo: nil)
                    strongSelf.statusUpdated?(.finished(.failure(error)))
                    return
                }
                storedRecordIDs = fetchedHistories.map {
                    $0.recordID
                }

                var uniqleHistoryForStore = [Int32: CHSesame2History]()
                
                histories.data.forEach{ history in
                    switch history {
                    case .manualElse(let data):
                        if storedRecordIDs?.contains(data.recordID) == false,
                           uniqleHistoryForStore[data.recordID] == nil {
                            uniqleHistoryForStore[data.recordID] = history
                        }
                    case .manualLocked(let data):
                        if storedRecordIDs?.contains(data.recordID) == false,
                           uniqleHistoryForStore[data.recordID] == nil {
                            uniqleHistoryForStore[data.recordID] = history
                        }
                    case .manualUnlocked(let data):
                        if storedRecordIDs?.contains(data.recordID) == false,
                           uniqleHistoryForStore[data.recordID] == nil {
                            uniqleHistoryForStore[data.recordID] = history
                        }
                    case .bleLock(let data):
                        if storedRecordIDs?.contains(data.recordID) == false,
                           uniqleHistoryForStore[data.recordID] == nil {
                            uniqleHistoryForStore[data.recordID] = history
                        }
                    case .bleUnLock(let data):
                        if storedRecordIDs?.contains(data.recordID) == false,
                           uniqleHistoryForStore[data.recordID] == nil {
                            uniqleHistoryForStore[data.recordID] = history
                        }
                    case .autoLock(let data):
                        if storedRecordIDs?.contains(data.recordID) == false,
                           uniqleHistoryForStore[data.recordID] == nil {
                            uniqleHistoryForStore[data.recordID] = history
                        }
                    case .autoLockUpdated(let data):
                        if storedRecordIDs?.contains(data.recordID) == false,
                           uniqleHistoryForStore[data.recordID] == nil {
                            uniqleHistoryForStore[data.recordID] = history
                        }
                    case .mechSettingUpdated(let data):
                        if storedRecordIDs?.contains(data.recordID) == false,
                           uniqleHistoryForStore[data.recordID] == nil {
                            uniqleHistoryForStore[data.recordID] = history
                        }
                    case .timeChanged(let data):
                        if storedRecordIDs?.contains(data.recordID) == false,
                           uniqleHistoryForStore[data.recordID] == nil {
                            uniqleHistoryForStore[data.recordID] = history
                        }
                    case .bleAdvParameterUpdated(let data):
                        if storedRecordIDs?.contains(data.recordID) == false,
                           uniqleHistoryForStore[data.recordID] == nil {
                            uniqleHistoryForStore[data.recordID] = history
                        }
                    case .driveLocked(let data):
                        if storedRecordIDs?.contains(data.recordID) == false,
                           uniqleHistoryForStore[data.recordID] == nil {
                            uniqleHistoryForStore[data.recordID] = history
                        }
                    case .driveUnlocked(let data):
                        if storedRecordIDs?.contains(data.recordID) == false,
                           uniqleHistoryForStore[data.recordID] == nil {
                            uniqleHistoryForStore[data.recordID] = history
                        }
                    case .driveFailed(let data):
                        if storedRecordIDs?.contains(data.recordID) == false,
                           uniqleHistoryForStore[data.recordID] == nil {
                            uniqleHistoryForStore[data.recordID] = history
                        }
                    case .none(let data):
                        if storedRecordIDs?.contains(data.recordID) == false,
                           uniqleHistoryForStore[data.recordID] == nil {
                            uniqleHistoryForStore[data.recordID] = history
                        }
                    }
                }
                
                Sesame2Store.shared.addHistories(Array(uniqleHistoryForStore.values), toDevice: strongSelf.sesame2)
                if strongSelf.fetchedResultsController.managedObjectContext.hasChanges {
                    try? strongSelf.fetchedResultsController.managedObjectContext.save()
                } else {
                    strongSelf.statusUpdated?(.finished(.success(true)))
                }

            case .failure(let error):
                L.d("!!!!!error",error)
                // todo kill the hint  if you got!!!
                // 這裡是個workaround
                // 理由:多人連線 sesame2 回 busy 或是歷史記憶體失敗回 None
                // 策略:失敗就去server 拿拿看 延遲網路請求等待隔壁連上的sesame2上傳完畢後拉取
                
//                let cmderror = error as NSError
//
//                if cmderror.code == strongSelf.sesame2Busy {
//                    L.d("策略:延遲網路請求等待隔壁連上的sesame2上傳完畢後拉取",cmderror.code)
//
//                } else {
//                    L.d("error",error)
//                    strongSelf.statusUpdated?(.finished(.failure(error)))
//                }
                
                L.d("!!!!!error",error)
                if CHConfiguration.shared.isHistoryStorageEnabled() == true,
                    (error as NSError).code == -1009 {
                    strongSelf.statusUpdated?(.finished(.success(true)))
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        strongSelf.getHistory(requestPage: 0)
                    }
                }
            }
        }
    }
    
    public var numberOfSections: Int {
        let numberOfSections = fetchedResultsController.sections?.count ?? 0
        return numberOfSections
    }
    
    public func numberOfRowsInSection(_ section: Int) -> Int {
        if let sections = fetchedResultsController.sections?.reversed() {
            return Array(sections)[section].numberOfObjects
        }
        return 0
    }
    
    public func cellViewModelForIndexPath(_ indexPath: IndexPath) -> Sesame2HistoryCellViewModel {
        guard let sections = fetchedResultsController.sections?.reversed(),
            let histories = Array(sections)[indexPath.section].objects as? [Sesame2HistoryMO] else {
                assertionFailure("fetchedResultsController.section error")
                return Sesame2HistoryCellViewModel(history: Sesame2HistoryMO())
        }
        return Sesame2HistoryCellViewModel(history: Array(histories.reversed())[indexPath.row])
    }
    
    public func titleForHeaderInSection(_ section: Int) -> String {
        guard let sectionInfo = fetchedResultsController.sections?.reversed()[section] else {
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
        guard let status = sesame2.mechStatus else {
                return nil
        }
        return angle2degree(angle: status.position)
    }
    
    public var isInLockRange: Bool? {
        sesame2.mechStatus?.isInLockRange
    }
    
    deinit {
        if CHConfiguration.shared.isHistoryStorageEnabled() == false {
            Sesame2Store.shared.deleteHistoriesForDevice(sesame2)
        }
        //        L.d("Sesame2RoomMainViewModel deinit")
    }
}

extension Sesame2HistoryViewModel: CHSesame2Delegate {
    
    public func onBleDeviceStatusChanged(device: CHSesame2,
                                         status: CHSesame2Status) {
        if status == .receivedBle {
            device.connect(){_ in}
        }
        statusUpdated?(.update(nil))
    }
    
    public func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        statusUpdated?(.update(nil))
    }
}
