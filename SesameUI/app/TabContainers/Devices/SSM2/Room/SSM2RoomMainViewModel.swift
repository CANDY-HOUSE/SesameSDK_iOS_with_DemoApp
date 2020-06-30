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

public protocol SSM2RoomMainViewModelDelegate {
    func rightButtonTappedWithSSM(_ ssm: CHSesameBleInterface)
}

public final class SSM2RoomMainViewModel: ViewModel {
    
    private let id = UUID()
    private var historyGroup = [String: [Sesame2History]]()
    private var sortedHistoryKeys: [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy/MM/dd"
        
        return historyGroup.keys.sorted {
            dateFormatter.date(from: $0)! < dateFormatter.date(from: $1)!
        }
    }
    var ssm: CHSesameBleInterface
    public var statusUpdated: ViewStatusHandler?
    var delegate: SSM2RoomMainViewModelDelegate?
    
    var title: String {
        if let device = SSMStore.shared.getPropertyForDevice(ssm) {
            return device.name ?? device.uuid!.uuidString
        } else {
            return ssm.deviceId.uuidString
        }
    }
    
    init(ssm: CHSesameBleInterface) {
        self.ssm = ssm
        ssm.connect()
    }
    
    public func viewWillAppear() {
        ssm.delegate = self
    }
    
    public func getHistory() {
    }
    
    private func setHistoryGroupAndSort(_ historys: [CHHistoryEvent]) {
        statusUpdated?(.received)
    }
    
    public var numberOfSections: Int {
        sortedHistoryKeys.count
    }
    
    public func numberOfRowsInSection(_ section: Int) -> Int {
        historyGroup[sortedHistoryKeys[section]]?.count ?? 0
    }
    
    public func headerViewModelForSection(_ section: Int) -> SSM2HistoryHeaderCellViewModel {
        let key = sortedHistoryKeys[section]
        return SSM2HistoryHeaderCellViewModel(historys: historyGroup[key]!)
    }
    
    public func cellViewModelForIndexPath(_ indexPath: IndexPath) -> SSM2HistoryCellViewModel {
        let key = sortedHistoryKeys[indexPath.section]
        let history = historyGroup[key]![indexPath.row]
        return SSM2HistoryCellViewModel(history: history)
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
    
    private func angle2degree(angle: Int16) -> Float {

        var degree = Float(angle % 1024)
        degree = degree * 360 / 1024
        if degree > 0 {
            degree = 360 - degree
        } else {
            degree = abs(degree)
        }
        return degree
    }
    
    public var isInLockRange: Bool? {
        ssm.mechStatus?.isInLockRange()
    }
    
    deinit {
        L.d("SSM2RoomMainViewModel deinit")
    }
}

extension SSM2RoomMainViewModel: CHSesameBleDeviceDelegate {
    
    public func onBleDeviceStatusChanged(device: CHSesameBleInterface,
                                         status: CHDeviceStatus) {
        if status == .receiveBle {
            device.connect()
        }
        statusUpdated?(.received)
    }
    
    public func onBleCommandResult(device: CHSesameBleInterface,
                                   command: SSM2ItemCode,
                                   returnCode: SSM2CmdResultCode) {
        if command == .history {
            statusUpdated?(.received)
        }
    }
}
