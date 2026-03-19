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

extension CHSesamebot2Event: CellSubItemDiscriptor {
    
    var title: String {
        return "\("co.candyhouse.sesame2.Scripts".localized) \(self.displayName)"
    }
    
    func iconWithDevice(_ device: CHDevice) -> String? {
        return device.currentStatusImage() + "-noBorder"
    }
    
    func convertToCellDescriptorModel(device: CHDevice, cellCls: AnyClass, click: (() -> Void)?) -> CHCellDescriptor {
        return CHCellDescriptor(cellCls: cellCls, rawValue: self) { cell in
            guard let emitCell = cell as? Hub3IREmitCell else {
                return
            }
            emitCell.clickHandler = click
            emitCell.device = device
            emitCell.configure(item: self)
        }
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
        didSet {
            updateTitle()
        }
    }
    var editedAlias: String?
    var aliasDirty = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationLeftTitleItem("co.candyhouse.sesame2.SaveScript".localized, #selector(onDoneButtonTapped))
        setNavigationRightItem("icons_outlined_addoutline", #selector(onNewButtonTapped))
        setupTitleTapView()
        configureTable()
    }
    
    private func setupTitleTapView() {
        let titleButton = UIButton(type: .system)
        titleButton.setTitleColor(.label, for: .normal)
        titleButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleButton.addTarget(self, action: #selector(onEditAliasTapped), for: .touchUpInside)
        navigationItem.titleView = titleButton
        updateTitle()
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
    
    private func normalizeBotAlias(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let pure = trimmed.hasPrefix("🎬")
            ? trimmed.replacingOccurrences(of: "🎬", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            : trimmed
        return "🎬 \(pure)"
    }

    private func stripBotAliasPrefix(_ input: String) -> String {
        return input.replacingOccurrences(of: "🎬", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func updateTitle() {
        let index = Int(getIndex())
        let fallback = eventData?.displayName ?? "\(index)"
        let titleName = editedAlias
            ?? BotScriptStore.shared.getAlias(deviceUUID: bot2Device.deviceId.uuidString, actionIndex: index)
            ?? fallback

        let text = "\(titleName)🖊️(\(eventData?.actions?.count ?? 0)/\(MAX_ACTION))"

        if let button = navigationItem.titleView as? UIButton {
            button.setTitle(text, for: .normal)
            button.sizeToFit()
        } else {
            self.title = text
        }
    }
    
    @objc private func onEditAliasTapped() {
        let index = Int(getIndex())
        let currentAlias = editedAlias
            ?? BotScriptStore.shared.getAlias(deviceUUID: bot2Device.deviceId.uuidString, actionIndex: index)
            ?? eventData?.displayName
            ?? "\(index)"

        let editableText = stripBotAliasPrefix(currentAlias)

        ChangeValueDialog.showOnTop(
            editableText,
            title: currentAlias
        ) { name in
            self.editedAlias = self.normalizeBotAlias(name)
            self.aliasDirty = true
            self.updateTitle()
        }
    }
    
    func handleAction(_ target: Bot2Action, _ isDelete: Bool, _ path: IndexPath) {
        isEventsChanged = true
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
                    let index = Int(self.getIndex())
                    if let alias = BotScriptStore.shared.getAlias(deviceUUID: self.bot2Device.deviceId.uuidString, actionIndex: index) {
                        self.editedAlias = alias
                        self.aliasDirty = false
                    }
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
        self.updateTitle()
    }
    
    private func getIndex() -> UInt8 {
        return UInt8(UserDefaults.standard.integer(forKey: bot2Device.deviceId.uuidString))
    }
    
    @objc func onNewButtonTapped() {
        guard let _ = self.eventData else { return }
        guard (self.eventData?.actions!.count)! < MAX_ACTION else { return }
        isEventsChanged = true
        self.eventData?.actions?.append(Bot2Action(action: .forward, time: 0))
        self.handleData()
    }
    
    @objc func onDoneButtonTapped() {
        guard let _ = self.eventData else { return }
        guard isEventsChanged || aliasDirty else {
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
                    let idx = Int(self.getIndex())
                    if self.aliasDirty, let alias = self.editedAlias {
                        BotScriptStore.shared.putAlias(deviceUUID: self.bot2Device.deviceId.uuidString, actionIndex: idx, alias: alias)
                    }
                    
                    NotificationCenter.default.post(
                        name: NSNotification.Name("Bot2AliasUpdated"),
                        object: self.bot2Device.deviceId.uuidString
                    )

                    let req = BotScriptRequest(
                        deviceUUID: self.bot2Device.deviceId.uuidString.uppercased(),
                        actionIndex: "\(idx)",
                        alias: self.aliasDirty ? self.editedAlias : nil,
                        isDefault: 1,
                        actionData: self.eventData?.toData().toHexString(),
                        displayOrder: BotScriptStore.shared.getDisplayOrder(deviceUUID: self.bot2Device.deviceId.uuidString, actionIndex: idx) ?? idx,
                        deleteAll: nil,
                        batchDisplayOrders: nil
                    )

                    CHAPIClient.shared.updateBotScript(req) { _ in }

                    self.isEventsChanged = false
                    self.aliasDirty = false
                    self.dismiss(animated: true, completion: { })
                }
            }
        }
    }
}

extension Bot2ScriptActionVC { // 設備列表排序
    override func positionChanged(currentIndex: IndexPath, newIndex: IndexPath) {
        guard newIndex != currentIndex else { return }
        isEventsChanged = true
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
