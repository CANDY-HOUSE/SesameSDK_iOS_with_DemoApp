//
//  SesameBotHistoryViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/10/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

//private let lockQueue = DispatchQueue(label: "co.sesameUI.SwitchHistory.queue")

//class SesameBotHistoryViewController: CHBaseViewController, UITableViewDataSource, UITableViewDelegate {
//
//    @IBOutlet weak var tableView: UITableView!
//    var dismissHandler: (()->Void)?
//
//    var sesameBot: CHSesameBot!
//    var requestPage: Int = -1
//
//    private var _histories = [CHSesameBotHistory]()
//    private var histories: [CHSesameBotHistory] {
//        set {
//            lockQueue.sync {
//                _histories = newValue
//            }
//        }
//
//        get {
//            lockQueue.sync {
//                return _histories
//            }
//        }
//
//    }
//
//    private var _sections = Set([String]())
//    private var sections: Set<String> {
//        set {
//            lockQueue.sync {
//                _sections = newValue
//            }
//        }
//
//        get {
//            lockQueue.sync {
//                _sections
//            }
//        }
//    }
//
//    private var _tableViewData = [String: [CHSesameBotHistory]]()
//    // MARK: Internal properties
//    var tableViewData: [String: [CHSesameBotHistory]] {
//        set {
//            lockQueue.sync {
//                _tableViewData = newValue
//            }
//        }
//
//        get {
//            lockQueue.sync {
//                return _tableViewData
//            }
//        }
//    }
//
//    let sesame2CircleContainer = UIView(frame: .zero)
//    var sesame2Circle = ShakeCircle(frame: .init(x: 0, y: 0, width: 90, height: 90))
//    var lockButton = UIButton(type: .custom)
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        let rightButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: "icons_filled_more"),
//                                              style: .done,
//                                              target: self,
//                                              action: #selector(navigateToSwitchSettingView))
//        navigationItem.rightBarButtonItem = rightButtonItem
//
//        lockButton.addSubview(sesame2Circle)
//        sesame2CircleContainer.addSubview(lockButton)
//        view.addSubview(sesame2CircleContainer)
//
//        sesame2CircleContainer.backgroundColor = .clear
//        sesame2Circle.backgroundColor = .clear
//
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(switchTapped))
//        sesame2Circle.addGestureRecognizer(tapGesture)
//        lockButton.setTitle(nil, for: .normal)
//
//        sesame2CircleContainer.autoPinRight(constant: -10)
//        sesame2CircleContainer.autoPinBottom(constant: -10)
//        sesame2CircleContainer.autoLayoutWidth(100)
//        sesame2CircleContainer.autoLayoutHeight(100)
//
//        sesame2Circle.autoPinCenter()
//        sesame2Circle.autoLayoutWidth(90)
//        sesame2Circle.autoLayoutHeight(90)
//
//        lockButton.autoPinCenter()
//        lockButton.autoLayoutWidth(90)
//        lockButton.autoLayoutHeight(90)
//
//        tableView.register(UITableViewHeaderFooterView.self,
//                           forHeaderFooterViewReuseIdentifier: "header")
//        tableView.register(UINib(nibName: "SwitchHistoryTableViewCell", bundle: nil), forCellReuseIdentifier: "SwitchHistoryTableViewCell")
//
//        tableView.separatorStyle = .none
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        sesameBot.delegate = self
//        title = sesameBot.deviceName
//        updateSwitchCircle()
//        getHistory(isScrollToBottom: true)
//    }
//
//    func getHistory(isScrollToBottom: Bool = false) {
//        requestPage += 1
////        sesameBot.getHistories(page: UInt(requestPage)) { result in
////            switch result {
////            case .success(let histories):
////                self.insertOldHistories(histories.data)
////                executeOnMainThread {
////                    for section in self.sections {
////                        self.tableViewData[section] = self.histories.filter({ $0.sectionIdentifier == section }).sorted(by: <)
////                    }
////                    self.tableView.reloadData()
////                    if isScrollToBottom {
////                        self.scrollToBottom()
////                    }
////                }
////            case .failure(let error):
////                executeOnMainThread {
////                    self.view.makeToast(error.errorDescription())
////                }
////            }
////        }
//    }
//
//    func insertOldHistories(_ histories: [CHSesameBotHistory]) {
//        let noDuplicateHistories = histories.filter { serverHistory -> Bool in
//            !self.histories.contains(where: { history -> Bool in
//                history.sortKey == serverHistory.sortKey
//            })
//        }.sorted(by: <)
//
//        if noDuplicateHistories.count == 0 {
//            return
//        }
//
//        for noDuplicateHistory in noDuplicateHistories {
//            self.histories.insert(noDuplicateHistory, at: 0)
//            sections.insert(noDuplicateHistory.sectionIdentifier)
//        }
//
//        let currentHistories = Array(self.histories).sorted(by: <)
//        for (index, history) in currentHistories.enumerated() {
//            guard index > 0 else {
//                continue
//            }
//            var previous = currentHistories[index - 1]
//            if history.isDriveUnlocked, previous.isBleUnLock {
//                previous.isUnlocked = true
//                self.histories.removeAll { someHistory -> Bool in
//                    someHistory.sortKey == history.sortKey
//                }
//            } else if history.isDriveLocked, previous.isBleLock {
//                previous.isLocked = true
//                self.histories.removeAll { someHistory -> Bool in
//                    someHistory.sortKey == history.sortKey
//                }
//            } else if history.isDriveLocked, previous.isAutoLock {
//                previous.isLocked = true
//                self.histories.removeAll { someHistory -> Bool in
//                    someHistory.sortKey == history.sortKey
//                }
//            }
//        }
//    }
//
//    func appendNewHistories(_ histories: [CHSesameBotHistory]) {
//
//        let noDuplicateHistories = histories.filter { serverHistory -> Bool in
//            !self.histories.contains(where: { history -> Bool in
//                history.sortKey == serverHistory.sortKey
//            })
//        }.sorted(by: <)
//
//        guard noDuplicateHistories.count > 0 else {
//            return
//        }
//
//        for noDuplicateHistory in noDuplicateHistories {
//            if var previous = self.histories.sorted(by: <).last {
//                if noDuplicateHistory.isDriveUnlocked, previous.isBleUnLock {
//                    previous.isUnlocked = true
//                } else if noDuplicateHistory.isDriveLocked, previous.isBleLock {
//                    previous.isLocked = true
//                } else if noDuplicateHistory.isDriveLocked, previous.isAutoLock {
//                    previous.isLocked = true
//                } else {
//                    self.histories.insert(noDuplicateHistory, at: 0)
//                    self.sections.insert(noDuplicateHistory.sectionIdentifier)
//                }
//            } else {
//                self.histories.insert(noDuplicateHistory, at: 0)
//                self.sections.insert(noDuplicateHistory.sectionIdentifier)
//            }
//        }
//    }
//
//    func updateSwitchCircle(intention: CHSesameBotIntention? = nil) {
//        lockButton.setBackgroundImage(UIImage.CHUIImage(named: sesameBot.currentStatusImage()), for: .normal)
//        if intention == .idle {
//            self.sesame2Circle.stopShake()
//        }
//        if intention == .moving {
//            self.sesame2Circle.startShake()
//        }
//    }
//
//    @objc func navigateToSwitchSettingView() {
//        let switchSettingViewController = SesameBotSettingViewController.instanceWithSwitch(sesameBot) {
//            self.navigationController?.popViewController(animated: true)
//            self.dismissHandler?()
//        }
//        navigationController?.pushViewController(switchSettingViewController,
//                                                 animated: true)
//    }
//
//    // MARK: SwtichCircleTapped
//    @objc func switchTapped() {
//        sesameBot.unlock(historytag: nil) { _ in
////            executeOnMainThread {
////                self.sesame2Circle.startAnimation()
////                    self.sesame2Circle.stopAnimation()
////            }
//        }
//    }
//
//    // MARK: - Table view data source
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        tableViewData.keys.count
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        let sortedKeys = tableViewData.keys.sorted(by: <)
//        let key = sortedKeys[section]
//        return tableViewData[key]!.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchHistoryTableViewCell", for: indexPath) as! SesameBotHistoryTableViewCell
//        configureCell(cell, atIndexPath: indexPath)
//        return cell
//    }
//
//    func configureCell(_ cell: SesameBotHistoryTableViewCell, atIndexPath indexPath: IndexPath) {
//        if indexPath.section == 0, indexPath.row == 0 {
//            cell.loadingIndicator.startAnimating()
//            cell.showLoadingIndicator()
//        } else {
//            cell.hideLoadingIndicator()
//        }
//
//        let sortedKeys = tableViewData.keys.sorted(by: <)
//        let key = sortedKeys[indexPath.section]
//        let historyModel = self.tableViewData[key]!.sorted(by: <)[indexPath.row]
//        cell.hideLoadingIndicator()
//        cell.eventImageView.image = UIImage.SVGImage(named: historyModel.avatarImage)
//        cell.dateTimeLabel.text = historyModel.dateTime
//        cell.eventLabel.text = historyModel.eventText
//        cell.historyTagLabel.text = historyModel.historyTagText
//        cell.descriptionTextView.text = historyModel.historyDetail
//    }
//
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") else {
//            return UITableViewHeaderFooterView()
//        }
//        headerView.tintColor = UIColor.sesame2Gray
//
//        let sortedKeys = tableViewData.keys.sorted(by: <)
//
//        if let label = headerView.subviews.filter({ $0.accessibilityIdentifier == "header label" }).first as? UILabel {
//
//            label.text = sortedKeys[section]
//            headerView.bringSubviewToFront(headerView)
//        } else {
//            let label = UILabel()
//            label.translatesAutoresizingMaskIntoConstraints = false
//            label.accessibilityIdentifier = "header label"
//            label.text = sortedKeys[section]
//            headerView.addSubview(label)
//            headerView.bringSubviewToFront(headerView)
//
//            let constraints = [
//                label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
//                label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 70),
//                label.widthAnchor.constraint(equalTo: headerView.widthAnchor),
//                label.heightAnchor.constraint(equalTo: headerView.heightAnchor)
//            ]
//            NSLayoutConstraint.activate(constraints)
//        }
//        return headerView
//    }
//
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        100
//    }
//
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//
//        if (tableView.isDragging || tableView.isDecelerating || tableView.isTracking),
//            indexPath.section == 0,
//            indexPath.row == 0 {
//            getHistory()
//        }
//    }
//
//    func scrollToBottom() {
//        let lastSections = self.tableView.numberOfSections - 1
//        guard lastSections >= 0 else {
//            self.tableView.setContentOffset(CGPoint(x: 0,
//                                                    y: self.tableView.contentSize.height),
//                                            animated: false)
//            return
//        }
//
//        let lastRow = self.tableView.numberOfRows(inSection: lastSections) - 1
//        guard lastRow >= 0 else {
//            self.tableView.setContentOffset(CGPoint(x: 0,
//                                                    y: self.tableView.contentSize.height),
//                                            animated: false)
//            return
//        }
//
//        let indexPath = IndexPath(row: lastRow, section: lastSections)
//
//        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
//    }
//}
//
//extension SesameBotHistoryViewController: CHSesameBotDelegate {
//    func onBleDeviceStatusChanged(device: CHSesameBot, status: CHSesameBotStatus, shadowStatus: CHSesameBotShadowStatus?) {
//        if status == .receivedBle() {
//            device.connect() { _ in }
//        }
//        executeOnMainThread {
//            self.updateSwitchCircle()
//        }
//    }
//
//    func onMechStatusChanged(device: CHSesameBot, status: CHSesameBotMechStatus, intention: CHSesameBotIntention) {
////        executeOnMainThread {
////            self.updateSwitchCircle(intention: intention)
////        }
//    }
//
//    func onHistoryReceived(device: SesameSDK.CHSesameBot, result: Result<SesameSDK.CHResultState<[SesameSDK.CHSesameBotHistory]>, Error>) {
//        switch result {
//        case .success(let histories):
//            self.appendNewHistories(histories.data)
//            executeOnMainThread {
//                for section in self.sections {
//                    self.tableViewData[section] = self.histories.filter({ $0.sectionIdentifier == section }).sorted(by: <)
//                }
//                self.tableView.reloadData()
//                self.scrollToBottom()
//            }
//        case .failure(let error):
//            let cmderror = error as NSError
//            L.d("!!!!!cmderror",cmderror.code)
//            executeOnMainThread {
//                self.view.makeToast(error.errorDescription())
//            }
//        }
//    }
//}
//
//extension SesameBotHistoryViewController {
//    static func instanceWithSwitch(_ switchDevice: CHSesameBot, dismissHandler: (()->Void)?) -> SesameBotHistoryViewController {
//        let sesameBothHistoryViewController = SesameBotHistoryViewController(nibName: "SesameBotHistoryViewController", bundle: nil)
//        sesameBothHistoryViewController.hidesBottomBarWhenPushed = true
//        sesameBothHistoryViewController.sesameBot = switchDevice
//        sesameBothHistoryViewController.dismissHandler = dismissHandler
//        return sesameBothHistoryViewController
//    }
//}
