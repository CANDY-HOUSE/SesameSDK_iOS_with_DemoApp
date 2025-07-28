// Sesame5HistoryViewController.swift
import UIKit
import SesameSDK

class Sesame5HistoryViewController: CHBaseTableViewController {

    // MARK: - Data model
    var sesame2: CHSesame5!
    private var histories = [String: [CHSesame5History]]()
    private var tableViewData = [String: [CHSesame5History]]()

    // MARK: - UI data
    private var cursor: UInt?
    /// 儲存前一次請求的 section 數，及第0個 section 的 row 數
    private var previousIndexPath = IndexPath(row: 0, section: 0)

    // MARK: - Flag
    private var isNoMoreDataToGet = false
    private var isReloadingTableView = false
    /// 是否需要刷新 table
    private var isHangingTableViewReload = false

    // MARK: - UI Component
    let sesame2CircleContainer = UIView(frame: .zero)
    var sesame2Circle = Sesame2Circle(frame: .init(x: 0, y: 0, width: 90, height: 90))
    var lockButton = UIButton(type: .custom)

    // MARK: - Callback
    var dismissHandler: (()->Void)?
    
    private var hasCheckedInitialLoad = false

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationRightItem("icons_filled_more", #selector(navigateToSesame2SettingView(_:)))
        
        view.addSubview(sesame2CircleContainer)
        sesame2CircleContainer.backgroundColor = .clear
        sesame2CircleContainer.autoPinRight(constant: -10)
        sesame2CircleContainer.autoPinBottom(constant: -10)
        sesame2CircleContainer.autoLayoutWidth(100)
        sesame2CircleContainer.autoLayoutHeight(100)
        sesame2CircleContainer.addSubview(lockButton)
        lockButton.setTitle(nil, for: .normal)
        lockButton.autoPinCenter()
        lockButton.autoLayoutWidth(90)
        lockButton.autoLayoutHeight(90)
        lockButton.addSubview(sesame2Circle)
        sesame2Circle.backgroundColor = .clear
        sesame2Circle.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sesame2CircleTapped)))
        sesame2Circle.autoPinCenter()
        sesame2Circle.autoLayoutWidth(90)
        sesame2Circle.autoLayoutHeight(90)
        
        tableView.register(UITableViewHeaderFooterView.self,
                           forHeaderFooterViewReuseIdentifier: "header")
        tableView.register(UINib(nibName: "Sesame2HistoryTableViewCell", bundle: nil), forCellReuseIdentifier: "Sesame2HistoryTableViewCell")

        tableView.separatorStyle = .none
        noContentView.isHidden = true
        tableView.isHidden = false

        prepareHapticFeedback()
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasCheckedInitialLoad = false
    }

    // MARK: Sesame2CircleTapped
    @objc func sesame2CircleTapped() {
        guard let device = self.sesame2 else { return }
        triggerHapticFeedback()
        self.sesame2?.toggle(historytag: device.hisTag,result: {_ in})
        UserLocationManager.shared.postCHDeviceLocation(sesame2!)
    }

    // MARK: updateSesame2Circle
    func updateSesame2Circle() {
        if let mechStatus = sesame2.mechStatus {
           let currentDegree = reverseDegree(angle: mechStatus.position)
            sesame2Circle.refreshUI(newPointerAngle: CGFloat(currentDegree),
                                    lockColor: sesame2.lockColor())
        }

        lockButton.setBackgroundImage(UIImage(named: sesame2.currentStatusImage()), for: .normal)
    }


    /// 拿歷史
    /// - Parameter isUserReqeust: 區分用戶下拉取得更多`過去`歷史，或是機械狀態發生改變主動取得`最新`歷史
    private func getHistory(isUserReqeust: Bool = true) {
//        L.d("[ss5][UI] getHistory")
        var reuqestCursor: UInt?
        // 如果是用戶下拉取得更多過去歷史，就帶`cursor`
        if isUserReqeust {
            reuqestCursor = self.cursor
        }
        // 記錄請求前的`第一個section的row數量`以及所有`section`的數量
        executeOnMainThread {
            if self.tableView.numberOfSections > 0 {
                self.previousIndexPath = IndexPath(row: self.tableView.numberOfRows(inSection: 0),
                                                   section: self.tableView.numberOfSections)
            }
        }
        
        // 調用歷史 API
//        L.d("[ss5][UI] getHistory",reuqestCursor)
        CHUserAPIManager.shared.getSubId {  [weak self] subId in
            guard let self = self else { return }
            self.sesame2.getHistories(cursor: reuqestCursor,subUUID: subId) { result in
                if case let .success(payload) = result {
                    self.handleHistories(isUserReqeust,reuqestCursor,payload.data.cursor,payload.data.histories)
                }
                if case let .failure(error) = result {
                    executeOnMainThread {
                        self.view.makeToast(error.errorDescription())
                        self.reloadTableView(isScrollToBottom: false)
                    }
                }
            }
        }
    }
    
    func handleHistories(_ isUserRequest: Bool,_ requestCursor:UInt?,_ cursor: UInt?, _ histories: [CHSesame5History]) {
        self.isNoMoreDataToGet = cursor == nil
        if isUserRequest && cursor != nil {
            self.cursor = cursor
        }
        let newHistoriesCount = self.addNewHistories(histories).count
        if newHistoriesCount > 0 {
            let shouldScrollToBottom = requestCursor == nil
            executeOnMainThread {
                self.reloadTableView(isScrollToBottom: shouldScrollToBottom)
            }
        } else if cursor == nil {
            executeOnMainThread {
                self.reloadTableView(isScrollToBottom: false)
            }
        }
    }

    // MARK: ReloadTableView
    func reloadTableView(isScrollToBottom: Bool) {

        isReloadingTableView = true

        // table 還要滾動時不刷新 table, 增加使用者體驗
        if tableView.contentOffset.y < 0 {
            // Determine whether to reload in following delegate methods.
            // scrollViewDidEndDecelerating
            // scrollViewDidEndDragging
            isHangingTableViewReload = true
        } else {
            tableViewData = histories

            UIView.performWithoutAnimation {
                tableView.reloadData()
                tableView.beginUpdates()
                tableView.endUpdates()
            }

            guard numberOfSections(in: tableView) > 0 else {
                return
            }

            if isScrollToBottom == true {
                scrollToBottom()
            } else {
                tableView.safelyScrollToRow(at: firstIndexPathBeforeUpdate(), position: .top, animated: false)
            }
            isReloadingTableView = false
            isHangingTableViewReload = false
        }
        
        // 检查是否需要在初始加载后自动加载更多
        if !self.hasCheckedInitialLoad {
            self.hasCheckedInitialLoad = true
            self.checkAndLoadMoreIfNeeded()
        }
    }
    
    private func checkAndLoadMoreIfNeeded() {
        if !isNoMoreDataToGet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                
                let firstIndexPath = IndexPath(row: 0, section: 0)
                if let visibleIndexPaths = self.tableView.indexPathsForVisibleRows,
                   visibleIndexPaths.contains(firstIndexPath),
                   !self.isReloadingTableView {
                    L.d("frey", "Auto-loading more after initial load")
                    self.getHistory()
                }
            }
        }
    }

    /// 計算出刷新 table 後要移動到的位置
    func firstIndexPathBeforeUpdate() -> IndexPath {

        // 如果已經拿到所有歷史
        if isNoMoreDataToGet {

            var historyCount = 0
            for key in tableViewData.keys {
                historyCount += tableViewData[key]!.count
            }
            // 所以歷史小於單頁長度
            if historyCount < 50 {
                return IndexPath(row: 0, section: 0)
            } else {
                // 請求後的 section 數比請求前還多
                if previousIndexPath.section < tableView.numberOfSections {
                    // 計算請求前的第一個row, 在請求後的位置
                    // 例如：請求前 section 0, 1, 2
                    //      請求後 section 0, 1, 2, 3
                    //      1. 請求後section數 - 請求前section數 = 要移動到的section位置 (請求前的第一個 section(0) 在請求後的 section 位置(1))
                    //      2. 要移動到的 section 位置的 row 數 - 請求前的第一個 section row 數 = 要移動到的 row 位置
                    let section = tableView.numberOfSections - previousIndexPath.section
                    let row = tableView.numberOfRows(inSection: section) - previousIndexPath.row
                    return IndexPath(row: max(row - 1, 0), section: max(section, 0))
                } else {
                    // section 數未發生變化，直些相減 row 數，得到要移動的位置
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

        self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
    }

    // MARK: - Navigation
    @objc private func navigateToSesame2SettingView(_ sender: Any) {
        navigationController?.pushViewController(Sesame5SettingViewController.instance(sesame2) { _ in /** self.getKeysFromCache()*/}, animated: true)
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        tableViewData.keys.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sortedKeys = tableViewData.keys.sorted(by: <)
        let key = sortedKeys[section]
        return tableViewData[key]!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Sesame2HistoryTableViewCell", for: indexPath) as! Sesame2HistoryTableViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    func configureCell(_ cell: Sesame2HistoryTableViewCell, atIndexPath indexPath: IndexPath) {
        if indexPath.section == 0, indexPath.row == 0, !isNoMoreDataToGet {
            cell.showLoadingIndicator()
        } else {
            cell.hideLoadingIndicator()
        }

        let sortedKeys = tableViewData.keys.sorted(by: <)
        let key = sortedKeys[indexPath.section]
        let historyModel = tableViewData[key]!.sorted(by: <)[indexPath.row]

        cell.eventImageView.image = UIImage.SVGImage(named: historyModel.avatarImage)
        cell.dateTimeLabel.text = historyModel.dateTime + historyModel.isCriticalText
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
            label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
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

        // 滑動到頂得時候拿更多歷史
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
            getHistory()
        }
        return true
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // table 滑動停止時 判斷是否需要刷新 table
        if isHangingTableViewReload == true {
            reloadTableView(isScrollToBottom: false)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // table 滑動停止時 判斷是否需要刷新 table
        if isHangingTableViewReload == true {
            reloadTableView(isScrollToBottom: false)
        }
    }

}

// MARK: - CHSesame2Delegate
extension Sesame5HistoryViewController: CHSesame5Delegate {
    func onBleDeviceStatusChanged(device: CHDevice,
                                  status: CHDeviceStatus,shadowStatus: CHDeviceStatus?) {
        if status == .receivedBle() {
            device.connect() {_ in}
        }
        executeOnMainThread {
            self.updateSesame2Circle()
        }
        if device.deviceStatus.loginStatus == .unlogined {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { // Change `2.0` to the desired number of seconds.
               // Code you want to be delayed
                self.getHistory(isUserReqeust: false)

            }
        }
    }

    func onMechStatus(device: CHDevice) {
        executeOnMainThread {
            self.updateSesame2Circle() // 如果未連上藍牙，又收網路通知的機械狀態變更，則主動去拉取`最新`歷史
        }
        // 锁状态变化3秒后，获取历史。（此界面中，锁状态变化后，历史数据会被读取并发送至后台。简单化处理，3秒后去读取历史）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.getHistory(isUserReqeust: false)
        }
    }

    /// 從藍芽得到的新增歷史
    func onHistoryReceived(device: SesameSDK.CHSesame5, result: Result<SesameSDK.CHResultState<[SesameSDK.CHSesame5History]>, Error>) {
        
        getHistory(isUserReqeust:false)
    }


    /// 新增歷史
    /// - Parameter histories: 傳入從server, 藍芽 拿到的歷史
    /// - Returns: 回傳過濾之後的歷史 (過濾掉開關鎖之外的歷史以及去重)
    @discardableResult
    func addNewHistories(_ histories: [CHSesame5History]) -> [CHSesame5History] {
//        let filteredHistories = histories
        var returnArray = [CHSesame5History]()
        for history in histories {
            if self.histories[history.sectionIdentifier] == nil {
                self.histories[history.sectionIdentifier] = [history]
                returnArray.append(history)
            } else {
                if !(self.histories[history.sectionIdentifier]!.contains {$0.historyData.timestamp == history.historyData.timestamp}) {
                    returnArray.append(history)
                    self.histories[history.sectionIdentifier]!.append(history)
                    self.histories[history.sectionIdentifier]!.sort(by: >)
                }
            }
        }
//        L.d("[ui][ss5] returnArray.count", returnArray.count)
        return returnArray
    }
}

// MARK: - Designated initializer
extension Sesame5HistoryViewController {
    static func instance(_ sesame5: CHSesame5, dismissHandler: (()->Void)?) -> Sesame5HistoryViewController {
        let sesame2HistoryViewController = Sesame5HistoryViewController(nibName: nil, bundle: nil)
        sesame2HistoryViewController.hidesBottomBarWhenPushed = true
        sesame2HistoryViewController.sesame2 = sesame5
        sesame2HistoryViewController.dismissHandler = dismissHandler
        return sesame2HistoryViewController
    }
}
