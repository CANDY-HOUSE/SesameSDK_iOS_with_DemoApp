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

let historyQueue = DispatchQueue(label: "seasmeUI.history",
                                 qos: .userInteractive,
                                 attributes: [],
                                 autoreleaseFrequency: .workItem,
                                 target: nil)

class Sesame2HistoryModel {
    private(set) var histories = [UInt: Sesame2HistoryMO]()
    private(set) var sortedGroupKeys = [String]()
    private(set) var recordIdGroups = [String: [UInt]]()
    
    func addHistories(_ histories: [Sesame2HistoryMO]) {
        historyQueue.sync {
            for history in histories {
                let group = history.date!.toYMD()
                let recordID = history.sortKey
                guard !self.histories.keys.contains(recordID) else {
                    continue
                }
                if self.sortedGroupKeys.contains(group) {
                    // Add to exist group
                    self.recordIdGroups[group]!.append(recordID)
                    self.recordIdGroups[group]!.sort(by: <)
                } else {
                    // New group
                    self.sortedGroupKeys.append(group)
                    self.sortedGroupKeys.sort()
                    self.recordIdGroups[group] = [recordID]
                }
                // Add new history
                self.histories[recordID] = history
            }
        }
    }
}

public final class Sesame2HistoryViewModel: ViewModel {
    private(set) var hasMoreData = true
    private let pageLength = 50
    private var requestPage = -1
    private let sesame2Busy = 7
    private var oldSectionsCount = 0
    private var oldRowsCount = 0
    private var isUserRequest = false
    
    private var dataModel = Sesame2HistoryModel()

    var delegate: Sesame2HistoryViewModelDelegate?
    var sesame2: CHSesame2

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
    
    private func getHistory(requestPage: Int, isUserRequest: Bool = true) {
        historyQueue.sync {
            if numberOfSections > 0 {
                oldSectionsCount = numberOfSections
                oldRowsCount = numberOfRowsInSection(0)
            }
            
            self.isUserRequest = isUserRequest
                
            sesame2.getHistories(page: UInt(requestPage)) { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                
                switch result{
                case.success(let histories):
                    if((histories is CHResultStateBLE<[CHSesame2History]>)){
                        L.d("🔔","UI從藍芽收到歷史拉<--" )
                        strongSelf.isUserRequest = false
                    }else{
                        L.d("🔔","UI從網路收到歷史拉<--" )
                    }
                    
                    //                L.d("hcia UI 收到歷史拉" ,(result is CHResultStateNetworks<Any>))
                    L.d("Request history page: \(requestPage), Result: \(histories.data.count) datas")
                    
                    if histories.data.count == 0 {
                        strongSelf.hasMoreData = false
                        strongSelf.isUserRequest = false
                        strongSelf.statusUpdated?(.finished(.success(true)))
                        L.d("!@# No more old data")
                        return
                    }
                    
                    if histories.data.count < strongSelf.pageLength, strongSelf.isUserRequest {
                        strongSelf.hasMoreData = false
                    }
                    
                    let historyFromServer = Sesame2Store
                        .shared
                        .historyModesFromCHHistories(histories.data,
                                                     forDevice: strongSelf.sesame2)
                    let histories = Array(strongSelf.dataModel.histories.values) + historyFromServer
                    
                    let uniqle = Set<Sesame2HistoryMO>(histories)
                    strongSelf.dataModel.addHistories(Array(uniqle))
                    
                    strongSelf.isUserRequest = false
                    
                    strongSelf.statusUpdated?(.finished(.success(true)))
                case .failure(let error):
                    strongSelf.isUserRequest = false
                    
                    // todo kill the hint  if you got!!!
                    // 這裡是個workaround
                    // 理由:多人連線 sesame2 回 notFound busy 或是歷史記憶體失敗回 None
                    // 策略:失敗就去server 拿拿看 延遲網路請求等待隔壁連上的sesame2上傳完畢後拉取
                    
                    let cmderror = error as NSError
                    L.d("!!!!!cmderror",cmderror.code)
                    
                    
                    if cmderror.code == 5  {
                        L.d("策略:延遲網路請求等待隔壁連上的sesame2上傳完畢後拉取",cmderror.code)
                        
                        
                        if CHConfiguration.shared.isHistoryStorageEnabled() == true,
                            (error as NSError).code == -1009 {
                            strongSelf.statusUpdated?(.finished(.success(true)))
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                strongSelf.getHistory(requestPage: 0, isUserRequest: false)
                            }
                        }
                    } else {
                        L.d("error",error)
                        strongSelf.statusUpdated?(.finished(.failure(error)))
                    }
                }
            }
        }
    }
    
    public var numberOfSections: Int {
        dataModel.sortedGroupKeys.count
    }
    
    public func numberOfRowsInSection(_ section: Int) -> Int {
        let groupKey = dataModel.sortedGroupKeys[section]
        return dataModel.recordIdGroups[groupKey]!.count
    }
    
    public func cellViewModelForIndexPath(_ indexPath: IndexPath) -> Sesame2HistoryCellViewModel {
        historyQueue.sync {
            let groupKey = dataModel.sortedGroupKeys[indexPath.section]
            let historyKey = dataModel.recordIdGroups[groupKey]![indexPath.row]
            let historyModel = dataModel.histories[historyKey]!
            return Sesame2HistoryCellViewModel(history: historyModel)
        }
    }
    
    public func titleForHeaderInSection(_ section: Int) -> String {
        return dataModel.sortedGroupKeys[section]
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
        L.d("Sesame2HistoryViewModel deinit")
    }
    
    public func firstIndexPathBeforeUpdate() -> IndexPath {
        historyQueue.sync {
            if !hasMoreData {
                if dataModel.histories.keys.count < pageLength {
                    return IndexPath(row: 0, section: 0)
                } else {
                    if oldSectionsCount < numberOfSections {
                        let row = numberOfRowsInSection(1) - oldRowsCount
                        return IndexPath(row: row, section: 1)
                    } else {
                        let row = numberOfRowsInSection(0) - oldRowsCount
                        return IndexPath(row: row, section: 0)
                    }
                }
            }
            let section = numberOfSections - oldSectionsCount
            let row = numberOfRowsInSection(section) - oldRowsCount
            return IndexPath(row: row, section: section)
        }
    }
}

extension Sesame2HistoryViewModel: CHSesame2Delegate {
    
    public func onBleDeviceStatusChanged(device: CHSesame2,
                                         status: CHSesame2Status,shadowStatus: CHSesame2ShadowStatus?) {
        if status == .receivedBle {
            device.connect(){_ in}
        }
        statusUpdated?(.update(nil))
    }
    
    public func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        statusUpdated?(.update(nil))
    }
}
