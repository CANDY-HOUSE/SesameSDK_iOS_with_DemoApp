//
//  CHSesame2HisotryViewController.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/9/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

//private let lockQueue = DispatchQueue(label: "co.sesameUI.history.queue")

class Sesame2HistoryViewController: CHBaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Data model
    var sesame2: CHSesame2!
    private var histories = [CHSesame2History]()
    private var sections = Set<String>()
    var tableViewData = [String: [CHSesame2History]]()
    
    // MARK: - UI data
    private let pageLength = 50
    private var currentPage = -1
    private var previousIndexPath = IndexPath(row: 0, section: 0)
    
    // MARK: - Flag
    private var isNoMoreDataToGet = false
    private var isReloadingTableView = false
    private var isHangingTableViewReload = false
    
    // MARK: - UI Component
    @IBOutlet weak var tableView: UITableView!
    var refreshControl = UIActivityIndicatorView(style: .gray)
    let sesame2CircleContainer = UIView(frame: .zero)
    var sesame2Circle = Sesame2Circle(frame: .init(x: 0, y: 0, width: 90, height: 90))
    var lockButton = UIButton(type: .custom)
    
    // MARK: - Callback
    var dismissHandler: (()->Void)?
    let getHistoryThrottle = Throttle()
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        let rightButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: "icons_filled_more"),
                                              style: .done,
                                              target: self,
                                              action: #selector(navigateToSesame2SettingView(_:)))
        navigationItem.rightBarButtonItem = rightButtonItem
        
        lockButton.addSubview(sesame2Circle)
        sesame2CircleContainer.addSubview(lockButton)
        view.addSubview(sesame2CircleContainer)
        tableView.addSubview(refreshControl)
        
        sesame2CircleContainer.backgroundColor = .clear
        sesame2Circle.backgroundColor = .clear
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sesame2CircleTapped))
        sesame2Circle.addGestureRecognizer(tapGesture)
        lockButton.setTitle(nil, for: .normal)
        
        refreshControl.startAnimating()
        
        sesame2CircleContainer.autoPinRight(constant: -10)
        sesame2CircleContainer.autoPinBottom(constant: -10)
        sesame2CircleContainer.autoLayoutWidth(100)
        sesame2CircleContainer.autoLayoutHeight(100)
        
        sesame2Circle.autoPinCenter()
        sesame2Circle.autoLayoutWidth(90)
        sesame2Circle.autoLayoutHeight(90)
        
        lockButton.autoPinCenter()
        lockButton.autoLayoutWidth(90)
        lockButton.autoLayoutHeight(90)

        refreshControl.autoPinCenterX()
        refreshControl.autoPinTopToSafeArea(true, constant: 2)
        refreshControl.autoLayoutWidth(20)
        refreshControl.autoLayoutHeight(20)
        
        tableView.register(UITableViewHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: "header")
        tableView.register(UINib(nibName: "Sesame2HistoryTableViewCell", bundle: nil), forCellReuseIdentifier: "Sesame2HistoryTableViewCell")
        
        tableView.separatorStyle = .none
        
        getHistory()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = sesame2.deviceName
        sesame2.delegate = self
        updateSesame2Circle()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            dismissHandler?()
        }
    }

    // MARK: Sesame2CircleTapped
    let toggleDebouncer = Debouncer()
    @objc func sesame2CircleTapped() {
        toggleDebouncer.execute {
            self.sesame2?.toggle(result: {_ in})
        }
    }
    
    // MARK: updateSesame2Circle
    func updateSesame2Circle() {
        if let mechStatus = sesame2.mechStatus {
           let currentDegree = angle2degree(angle: mechStatus.position)
            sesame2Circle.refreshUI(newPointerAngle: CGFloat(currentDegree),
                                    lockColor: sesame2.lockColor())
        }
        lockButton.setBackgroundImage(UIImage.CHUIImage(named: sesame2.currentStatusImage()), for: .normal)
    }
    
    // MARK: Get History
    private func getHistory(isUserReqeust: Bool = true) {
        var requestPage = 0
        if isUserReqeust {
            currentPage += 1
            requestPage = currentPage
        }
        if tableView.numberOfSections > 0 {
            self.previousIndexPath = IndexPath(row: tableView.numberOfRows(inSection: 0),
                                               section: tableView.numberOfSections)
        }
        
        sesame2.getHistories(page: UInt(requestPage)) { result in
            
            if case let .success(histories) = result {
                // No more data to get
                if histories.data.count == 0 {
                    self.isNoMoreDataToGet = true
                    executeOnMainThread {
                        self.refreshControl.removeFromSuperview()
                        self.reloadTableView(isScrollToBottom: false)
                    }
                    return
                }
                
                // Is invoked via user event.
                if isUserReqeust {
                    if histories.data.count < self.pageLength {
                        self.isNoMoreDataToGet = true
                    } else {
                        self.isNoMoreDataToGet = false
                    }
                }

                self.addNewHistories(histories.data)
                
                executeOnMainThread {
                    self.refreshControl.removeFromSuperview()
                    if requestPage == 0 {
                        self.reloadTableView(isScrollToBottom: true)
                    } else {
                        self.reloadTableView(isScrollToBottom: false)
                    }
                }
            } else {
                executeOnMainThread {
                    self.refreshControl.removeFromSuperview()
                    self.reloadTableView(isScrollToBottom: false)
                }
            }
        }
    }
    
    // MARK: ReloadTableView
    func reloadTableView(isScrollToBottom: Bool) {

        isReloadingTableView = true
        
        if tableView.contentOffset.y < 0 {
            // Determine whether to reload in following delegate methods.
            // scrollViewDidEndDecelerating
            // scrollViewDidEndDragging
            isHangingTableViewReload = true
        } else {
            for section in sections {
                tableViewData[section] = self.histories.filter({ $0.sectionIdentifier == section }).sorted(by: <)
            }
            tableView.reloadData()
            
            guard numberOfSections(in: tableView) > 0 else {
                return
            }
            
            if isScrollToBottom == true {
                scrollToBottom()
            } else {
                let indexPath = firstIndexPathBeforeUpdate()
                tableView.scrollToRow(at: indexPath, at: .top, animated: false)
            }
            isReloadingTableView = false
            isHangingTableViewReload = false
        }
    }
    
    func firstIndexPathBeforeUpdate() -> IndexPath {
        if isNoMoreDataToGet {
            
            var historyCount = 0
            for key in tableViewData.keys {
                historyCount += tableViewData[key]!.count
            }
            
            if historyCount < pageLength {
                return IndexPath(row: 0, section: 0)
            } else {
                if previousIndexPath.section < tableView.numberOfSections {
                    let section = tableView.numberOfSections - previousIndexPath.section
                    let row = tableView.numberOfRows(inSection: section) - previousIndexPath.row
                    return IndexPath(row: max(row - 1, 0), section: max(section, 0))
                } else {
                    let row = tableView.numberOfRows(inSection: 0) - previousIndexPath.row
                    return IndexPath(row: max(row - 1, 0), section: 0)
                }
            }
        }
        
        let section = tableView.numberOfSections - previousIndexPath.section
        var row = 0
        if previousIndexPath.section > 0 {
            row = tableView.numberOfRows(inSection: section) - previousIndexPath.row
        }
        
        return IndexPath(row: max(row - 1, 0), section: max(section, 0))
    }
    
    func scrollToBottom() {
        let lastSections = self.tableView.numberOfSections - 1
        guard lastSections >= 0 else {
            self.tableView.setContentOffset(CGPoint(x: 0,
                                                    y: self.tableView.contentSize.height),
                                            animated: false)
            return
        }

        let lastRow = self.tableView.numberOfRows(inSection: lastSections) - 1
        guard lastRow >= 0 else {
            self.tableView.setContentOffset(CGPoint(x: 0,
                                                    y: self.tableView.contentSize.height),
                                            animated: false)
            return
        }

        let indexPath = IndexPath(row: lastRow, section: lastSections)
        
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }
    
    // MARK: - Navigation
    @objc private func navigateToSesame2SettingView(_ sender: Any) {
        let sesame2SettingViewController = Sesame2SettingViewController.instanceWithSesame2(sesame2) { isReset in
            if isReset {
                self.navigationController?.popViewController(animated: true)
                self.dismissHandler?()
            }
        }
        navigationController?.pushViewController(sesame2SettingViewController,
                                                 animated: true)
    }
    
    // MARK: - UITableViewDataSource & UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        tableViewData.keys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sortedKeys = tableViewData.keys.sorted(by: <)
        let key = sortedKeys[section]
        return tableViewData[key]!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Sesame2HistoryTableViewCell", for: indexPath) as! Sesame2HistoryTableViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: Sesame2HistoryTableViewCell, atIndexPath indexPath: IndexPath) {
        if indexPath.section == 0, indexPath.row == 0, !isNoMoreDataToGet {
            cell.loadingIndicator.startAnimating()
            cell.showLoadingIndicator()
        } else {
            cell.hideLoadingIndicator()
        }
        
        let sortedKeys = tableViewData.keys.sorted(by: <)
        let key = sortedKeys[indexPath.section]
        let historyModel = tableViewData[key]!.sorted(by: <)[indexPath.row]
        
        cell.eventImageView.image = UIImage.SVGImage(named: historyModel.avatarImage)
        cell.dateTimeLabel.text = historyModel.dateTime
        cell.historyTypeImageView.image = UIImage.SVGImage(named: historyModel.historyTypeImage, fillColor: .lockGray)
        cell.historyTagLabel.text = historyModel.historyTagText
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") else {
            return UITableViewHeaderFooterView()
        }
        headerView.tintColor = UIColor.sesame2Gray
        
        let sortedKeys = tableViewData.keys.sorted(by: <)

        if let label = headerView.subviews.filter({ $0.accessibilityIdentifier == "header label" }).first as? UILabel {
            
            label.text = sortedKeys[section]
            headerView.bringSubviewToFront(headerView)
        } else {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.accessibilityIdentifier = "header label"
            label.text = sortedKeys[section]
            headerView.addSubview(label)
            headerView.bringSubviewToFront(headerView)

            let constraints = [
                label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 70),
                label.widthAnchor.constraint(equalTo: headerView.widthAnchor),
                label.heightAnchor.constraint(equalTo: headerView.heightAnchor)
            ]
            NSLayoutConstraint.activate(constraints)
        }
        return headerView
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        guard !isNoMoreDataToGet else {
            return
        }
        
        if (tableView.isDragging || tableView.isDecelerating || tableView.isTracking),
            indexPath.section == 0,
            indexPath.row == 0,
            isReloadingTableView == false {
            getHistory()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0,
           indexPath.row == 0 {
            if !isNoMoreDataToGet {
                return 120
            } else {
                return 60
            }
        } else {
            return 60
        }
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        guard !isNoMoreDataToGet else {
            return true
        }
        
        if !isNoMoreDataToGet, isReloadingTableView == false {
            addRefreshControlIndicator()
            getHistory()
        }
        return true
    }
    
    func addRefreshControlIndicator() {
        refreshControl.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(refreshControl)
        tableView.sendSubviewToBack(refreshControl)
        refreshControl.startAnimating()
        let constraints = [
            refreshControl.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            refreshControl.topAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor,
                                                 constant: 2),
            refreshControl.widthAnchor.constraint(equalToConstant: 20),
            refreshControl.heightAnchor.constraint(equalToConstant: 20)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if isHangingTableViewReload == true {
            reloadTableView(isScrollToBottom: false)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if isHangingTableViewReload == true {
            reloadTableView(isScrollToBottom: false)
        }
    }
    
    deinit {
        L.d("history", "deinit history")
    }
}

// MARK: - CHSesame2Delegate
extension Sesame2HistoryViewController: CHSesame2Delegate {
    func onBleDeviceStatusChanged(device: SesameLock,
                                  status: CHSesame2Status,shadowStatus: CHSesame2ShadowStatus?) {
        if status == .receivedBle() {
            device.connect() {_ in}
        }
        executeOnMainThread {
            self.updateSesame2Circle()
        }
    }
    
    func onMechStatusChanged(device: CHSesame2, status: SesameProtocolMechStatus, intention: CHSesame2Intention) {
        executeOnMainThread {
            self.updateSesame2Circle()
            if device.deviceStatus.loginStatus == .unlogined {
                self.getHistoryThrottle.execute {
                    self.getHistory(isUserReqeust: false)
                }
            }
        }
    }
    
    func onHistoryReceived(device: SesameSDK.CHSesame2, result: Result<SesameSDK.CHResultState<[SesameSDK.CHSesame2History]>, Error>) {
        if case let .success(histories) = result {
            if histories.data.count == 0 {
                return
            }
            self.addNewHistories(histories.data)

            executeOnMainThread {
                self.refreshControl.removeFromSuperview()
                self.reloadTableView(isScrollToBottom: true)
            }
        } else if case let .failure(error) = result {
            // 理由:多人連線 sesame2 回 busy:7  notfound:5
            if (error as NSError).code == 7 || (error as NSError).code == 5 {
                self.getHistoryThrottle.execute {
                    self.getHistory(isUserReqeust: false)
                }
            }
        }
    }
    
    // MARK: - appendNewHistories
    func addNewHistories(_ histories: [CHSesame2History]) {
        let filteredHistories = histories.filter { serverHistory -> Bool in
            !self.histories.contains(where: { history -> Bool in
                history.sortKey == serverHistory.sortKey
            }) &&
            (serverHistory.isAutoLock || serverHistory.isLock || serverHistory.isManualUnlocked || serverHistory.isUnLock || serverHistory.isManualLocked)
        }.sorted(by: <)

        guard filteredHistories.count > 0 else {
            return
        }
        
        for history in filteredHistories {
            self.histories.insert(history, at: 0)
            sections.insert(history.sectionIdentifier)
        }
        
        self.histories.sort(by: <)
    }
}

// MARK: - Designated initializer
extension Sesame2HistoryViewController {
    static func instanceWithSesame2(_ sesame2: CHSesame2, dismissHandler: (()->Void)?) -> Sesame2HistoryViewController {
        let sesame2HistoryViewController = Sesame2HistoryViewController(nibName: "Sesame2HistoryViewController", bundle: nil)
        sesame2HistoryViewController.hidesBottomBarWhenPushed = true
        sesame2HistoryViewController.sesame2 = sesame2
        sesame2HistoryViewController.dismissHandler = dismissHandler
        return sesame2HistoryViewController
    }
}
