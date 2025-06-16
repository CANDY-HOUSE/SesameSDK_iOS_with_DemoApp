//
//  Bot2ScriptActionVC.swift
//  SesameUI
//
//  Created by eddy on 2023/12/15.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import SesameSDK
import UIKit

extension Bot2Action {
    
    func convertToCellDescriptorModel(cellCls: AnyClass, changeListenerHandler: ((Bot2Action, _ cell: UITableViewCell, Bool) -> Void)?) -> CHCellDescriptor {
        return CHCellDescriptor(cellCls: cellCls, rawValue: self) { cell in
            cell.configure(item: self)
            (cell as? Bot2ScriptActionCell)?.onActionChange = { action in
                changeListenerHandler!(action, cell as! UITableViewCell, false)
            }
            (cell as? Bot2ScriptActionCell)?.onDeleteTapped = { action in
                changeListenerHandler!(action, cell as! UITableViewCell, true)
            }
        }
    }
    
    var actionIcon: String {
        return [
            BotActionType.forward: "icon_turnright",
            BotActionType.reverse: "icon_turnleft",
            BotActionType.sleep: "icon_sleep",
            BotActionType.stop: "icon_stop",
        ][self.action]!
    }
    
    var actionType: BotActionType {
        var type = self.action
        if type.rawValue + 1 > BotActionType.sleep.rawValue {
            type = BotActionType.forward
        } else {
            type = BotActionType(rawValue: type.rawValue + 1)!
        }
        return type
    }
}

extension UInt8 {
    
   /*
    Bot2脚本改成100毫秒做单位，把范围改成0到25.4秒，不用修改现在的协议。
    APP UI只改显示范围从0到25.4秒，
    固件之定时器乘以1000换算为毫秒的地方改为乘以100即可。
    
    以后缓过来后再做成 连 每个动作的1000、100都可以调整
    */
    var displayedActionTime: String {
        return Int(self) - MAX_ACTION_TIME != 0 ? "\(String(format: "%.1f", Double(self) * 0.1))\("co.candyhouse.sesame2.sec".localized)" : "co.candyhouse.sesame2.future".localized
    }
}

extension CHSesamebot2Event {
    var displayName: String {
        return String(data: Data(name), encoding: .utf8)!
    }
}

private let MAX_ACTION = 20
let MAX_ACTION_TIME = 255

class Bot2ScriptActionVC: CHBaseViewController, ShareAlertConfigurator {
    
    var bot2Device: CHSesameBot2!
    var reorderTableView: LongPressReorderTableView!
    var tableViewProxy: CHTableViewProxy!
    var isEventsChanged = false
    var eventData: CHSesamebot2Event? {
        willSet {
            isEventsChanged = eventData != nil
        }
        didSet {
            if let nameStr = eventData?.displayName {
                self.title = "\(nameStr)(\(eventData?.actions?.count ?? 0)/\(MAX_ACTION))"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationLeftTitleItem("co.candyhouse.sesame2.SaveScript".localized, #selector(onDoneButtonTapped))
        setNavigationRightItem("icons_outlined_addoutline", #selector(onNewButtonTapped))
        configureTable()
    }
    
    func configureTable() {
        tableViewProxy = CHTableViewProxy(superView: self.view, selectHandler: { [unowned self] item, path in
            self.modalAlert(item.rawValue as! Bot2Action, path)
        } ,emptyPlaceholder: "co.candyhouse.sesame2.AddScript".localized)
        tableViewProxy.configureTableHeader(nil, nil)
        tableViewProxy.tableView.rowHeight = 80
        readScriptInfomation()
        // 長摁拖動排序
        reorderTableView = LongPressReorderTableView(tableViewProxy.tableView,selectedRowScale: .big)
        reorderTableView.delegate = self
        reorderTableView.enableLongPressReorder()
    }
    
    func handleAction(_ target: Bot2Action, _ isDelete: Bool, _ path: IndexPath) {
        if isDelete {
            self.eventData?.actions!.remove(at: path.row)
        } else {
            self.eventData?.actions![path.row] = target
        }
        self.handleData()
    }
    
    func modalAlert(_ action: Bot2Action, _ path: IndexPath) {
        struct PickerItem: PickerItemDiscriptor {
            var displayName: String = ""
            var selectHandler: ((PickerItemDiscriptor) -> Void)?
        }
        let times = Array(1...MAX_ACTION_TIME)
        var copyedAction = action
        let items = times.map { item -> PickerItem in
            let name = UInt8(item).displayedActionTime
            return PickerItem(displayName: name) { it in
                copyedAction.time = UInt8(item)
            }
        }
        let pickerVC = PickerController(items: items, isShowToolbar: false) { [unowned self] in
            self.handleAction(copyedAction, false, path)
        }
        pickerVC.modalPresentationStyle = .overFullScreen
        pickerVC.modalTransitionStyle = .coverVertical
        present(pickerVC, animated: true, completion: nil)
        if let findIdx = times.firstIndex(where: { $0 == action.time }) {
            pickerVC.pickerView.selectRow(findIdx, inComponent: 0, animated: true)
        } else {
            // 若没有默认值(新增 action)，弹起后 设置第一个为默认值
            copyedAction.time = UInt8(times[0])
        }
    }
    
    func readScriptInfomation() {
        bot2Device.getCurrentScript(index: getIndex()) { [weak self] getResult in
            guard let self = self else { return }
            executeOnMainThread {
                if case let .failure(error) = getResult {
                    self.tableViewProxy.handleFailedDataSource(error)
                } else if case let .success(event) = getResult {
                    self.eventData = event.data
                    if self.eventData?.actionLength ?? 0 < 1 {
                        self.eventData?.actions = [Bot2Action]()
                    }
                    self.handleData()
                }
            }
        }
    }
    
    func handleData() {
        guard let acts = self.eventData?.actions else { return }
        let discriptors = acts.map { it -> CHCellDescriptor in
            return it.convertToCellDescriptorModel(cellCls: Bot2ScriptActionCell.self) { [weak self] action, cell, isDel in
                guard let self = self else { return }
                let idxPath = self.tableViewProxy.tableView.indexPath(for: cell)
                guard let path = idxPath else { return }
                self.handleAction(action, isDel, path)
            }
        }
        self.tableViewProxy.handleSuccessfulDataSource(nil, discriptors)
    }
    
    private func getIndex() -> UInt8 {
        return UInt8(UserDefaults.standard.integer(forKey: bot2Device.deviceId.uuidString))
    }
    
    @objc func onNewButtonTapped() {
        guard let _ = self.eventData else { return }
        guard (self.eventData?.actions!.count)! < MAX_ACTION else { return }
        self.eventData?.actions?.append(Bot2Action(action: .forward, time: 0))
        self.handleData()
    }
    
    @objc func onDoneButtonTapped() {
        guard let _ = self.eventData else { return }
        guard isEventsChanged == true else {
            dismiss(animated: true, completion: { })
            return
        }
        saveToDevice()
    }
    
    func saveToDevice() {
        if let actionsCount = eventData?.actions?.count {
            eventData?.actionLength = UInt8(actionsCount)
        }
        ViewHelper.showLoadingInView(view: view)
        bot2Device.sendClickScript(index: getIndex(), script: (eventData?.toData())!) { [weak self] getResult in
            guard let self = self else { return }
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.view)
                if case let .failure(error) = getResult {
                    self.view.makeToast(error.errorDescription())
                } else if case .success(_) = getResult {
                    self.dismiss(animated: true, completion: { })
                }
            }
        }
    }
}

extension Bot2ScriptActionVC { // 設備列表排序
    override func positionChanged(currentIndex: IndexPath, newIndex: IndexPath) {
        guard newIndex != currentIndex else { return }
        let movedObject = eventData?.actions![currentIndex.row]
        eventData?.actions!.remove(at: currentIndex.row)
        eventData?.actions!.insert(movedObject!, at: newIndex.row)
    }
    
    override func reorderFinished(initialIndex: IndexPath, finalIndex: IndexPath) { }
}


extension Bot2ScriptActionVC {
    static func instance(_ device: CHSesameBot2) -> Bot2ScriptActionVC {
        let vc =  Bot2ScriptActionVC()
        vc.bot2Device = device
        _ = UINavigationController(rootViewController: vc)
        return vc
    }
}
