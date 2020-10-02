//
//  CHSesame2HisotryViewController.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/9/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

class Sesame2HistoryViewController: CHBaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Data model
    var sesame2: CHSesame2!
    private var historyModel = Sesame2HistoryModel()
    
    // MARK: - UI data
    private let pageLength = 50
    private var requestPage = -1
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
        let device = Sesame2Store.shared.getSesame2Property(sesame2)
        title = device?.name ?? sesame2.deviceId!.uuidString
        sesame2.delegate = self
        updateSesame2Circle()
    }
    
    // MARK: - Methods
    
    
    
    // MARK: Sesame2CircleTapped
    @objc func sesame2CircleTapped() {
        sesame2.toggle { _ in
            
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
    public func getHistory() {
        requestPage += 1
        getHistory(requestPage: requestPage)
    }
    
    private func getHistory(requestPage: Int, isUserReqeust: Bool = true) {
        if tableView.numberOfSections > 0 {
            self.previousIndexPath = IndexPath(row: tableView.numberOfRows(inSection: 0),
                                               section: tableView.numberOfSections)
        }
        
        sesame2.getHistories(page: UInt(requestPage)) { result in
            
            switch result{
            case.success(let histories):
                
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
                
                let historiesFromServer = Sesame2HistoryModel.historyModelsFromCHHistories(histories.data,
                                                                                        forDevice: self.sesame2)
                self.historyModel.addOldHistories(historiesFromServer)
                
                executeOnMainThread {
                    self.refreshControl.removeFromSuperview()
                    if requestPage == 0 {
                        self.reloadTableView(isScrollToBottom: true)
                    } else {
                        self.reloadTableView(isScrollToBottom: false)
                    }
                }
            case .failure(let error):
                L.d("error",error)
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
            historyModel.reloadData()
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
            for key in historyModel.tableViewData.keys {
                historyCount += historyModel.tableViewData[key]!.count
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
        let sesame2SettingViewController = Sesame2SettingViewController.instanceWithSesame2(sesame2) {
            self.navigationController?.popViewController(animated: true)
            self.dismissHandler?()
        }
        navigationController?.pushViewController(sesame2SettingViewController,
                                                 animated: true)
    }
    
    // MARK: - UITableViewDataSource & UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        historyModel.tableViewData.keys.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sortedKeys = historyModel.tableViewData.keys.sorted(by: <)
        let key = sortedKeys[section]
        return historyModel.tableViewData[key]!.count
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
        
        let sortedKeys = historyModel.tableViewData.keys.sorted(by: <)
        let key = sortedKeys[indexPath.section]
        let historyModel = self.historyModel.tableViewData[key]!.sorted(by: <)[indexPath.row]
        
        cell.eventImageView.image = UIImage.SVGImage(named: historyModel.avatarImage)
        cell.dateTimeLabel.text = historyModel.dateTime
        cell.eventLabel.text = historyModel.eventText
        cell.historyTagLabel.text = historyModel.historyTagText
        cell.descriptionTextView.text = historyModel.historyDetail
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") else {
            return UITableViewHeaderFooterView()
        }
        headerView.tintColor = UIColor.sesame2Gray
        
        let sortedKeys = historyModel.tableViewData.keys.sorted(by: <)

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
                return 200
            } else {
                return 100
            }
        } else {
            return 100
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
}

// MARK: - CHSesame2Delegate
extension Sesame2HistoryViewController: CHSesame2Delegate {
        
    func onBleDeviceStatusChanged(device: CHSesame2,
                                         status: CHSesame2Status,shadowStatus: CHSesame2ShadowStatus?) {
        if status == .receivedBle {
            device.connect(){_ in}
        }
        executeOnMainThread {
            self.updateSesame2Circle()
        }
    }
    
    func onMechStatusChanged(device: CHSesame2, status: CHSesame2MechStatus, intention: CHSesame2Intention) {
        executeOnMainThread {
            self.updateSesame2Circle()
        }
    }
    
    func onHistoryReceived(device: CHSesame2, result: Result<CHResultState<[CHSesame2History]>, Error>) {
        executeOnMainThread {
            switch result {
            case.success(let histories):
                
                if histories.data.count == 0 {
                    return
                }
                
                let historiesFromSesame2 = Sesame2HistoryModel.historyModelsFromCHHistories(histories.data,
                                                                                        forDevice: self.sesame2)
                self.historyModel.addNewHistories(historiesFromSesame2)
                
                executeOnMainThread {
                    self.refreshControl.removeFromSuperview()
                    self.reloadTableView(isScrollToBottom: true)
                }
            case .failure(let error):
                    
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
                        executeOnMainThread {
                            self.reloadTableView(isScrollToBottom: true)
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.getHistory(requestPage: 0, isUserReqeust: false)
                        }
                    }
                } else {
                    L.d("error",error)
                }
            }
        }
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
