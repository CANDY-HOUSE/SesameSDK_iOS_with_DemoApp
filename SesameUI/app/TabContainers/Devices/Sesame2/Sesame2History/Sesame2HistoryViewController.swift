//
//  Sesame2HistoryViewController.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/10/14.
//  Copyright © 2019 CandyHouse. All rights reserved.
//


import UIKit
import SesameSDK
import CoreBluetooth
import CoreData

class Sesame2HistoryViewController: CHBaseViewController {
    // MARK: - ViewModel
    var viewModel: Sesame2HistoryViewModel!
    // MARK: - UI Components
    @IBOutlet weak var historyTable: UITableView!
    @IBOutlet weak var sesameCircle: Sesame2Circle!
    @IBOutlet weak var Locker: UIButton!
    var refreshControl = UIActivityIndicatorView(style: .gray)
    // MARK: - Flag
    private var isNeedScrollToBottom = true
    private var canRefresh = true
    private var isLoadingContent = false
    private var isFirstTimeEnterTheView = true
    private var isScrollToTopTapped = false
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super .viewDidLoad()
        assert(viewModel != nil, "Sesame2RoomMainViewModel should not be nil.")
        
        let rightButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: "icons_filled_more"), style: .done, target: self, action: #selector(handleRightBarButtonTapped(_:)))
              navigationItem.rightBarButtonItem = rightButtonItem
        
        viewModel.statusUpdated = { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            switch status {
            case .loading:
                break
            case .update:
                executeOnMainThread {
                    strongSelf.updataSesame2UI()
                }
            case .finished(let result):
                switch result {
                case .success(_):
                    executeOnMainThread {
                        strongSelf.canRefresh = strongSelf.viewModel.hasMoreData
                        strongSelf.refreshControl.removeFromSuperview()
                        L.d("😀 Result is back")
                        strongSelf.reloadContent()
                    }
                case .failure(let error):
                    strongSelf.isScrollToTopTapped = false
                    executeOnMainThread {
                        strongSelf.view.makeToast(error.errorDescription())
                    }
                }
            }
        }

        historyTable.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "header")
        
        addRefreshControlIndicator()
        viewModel.loadMore()

        historyTable.register(UINib(nibName: "Sesame2HistoryLoadingTableViewCell", bundle: nil), forCellReuseIdentifier: "Sesame2HistoryLoadingTableViewCell")
    }
    
    func addRefreshControlIndicator() {
        refreshControl.translatesAutoresizingMaskIntoConstraints = false
        historyTable.addSubview(refreshControl)
        historyTable.sendSubviewToBack(refreshControl)
        refreshControl.startAnimating()
        let constraints = [
            refreshControl.centerXAnchor.constraint(equalTo: historyTable.centerXAnchor),
            refreshControl.topAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor,
                                                 constant: 2),
            refreshControl.widthAnchor.constraint(equalToConstant: 20),
            refreshControl.heightAnchor.constraint(equalToConstant: 20)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updataSesame2UI()
        viewModel.viewWillAppear()
        titleLabel.text = viewModel.title
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isFirstTimeEnterTheView = false
        if CHConfiguration.shared.isHistoryStorageEnabled() {
            isNeedScrollToBottom = false
        }
    }
    
    // MARK: Methods
    fileprivate func scrollToBottomWithAnimation(_ animation: Bool = true) {
        executeOnMainThread {
            let lastSections = self.historyTable.numberOfSections - 1
            guard lastSections >= 0 else {
                self.historyTable.setContentOffset(CGPoint(x: 0,
                                                           y: self.historyTable.contentSize.height),
                                                   animated: animation)
                return
            }
            
            let lastRow = self.historyTable.numberOfRows(inSection: lastSections) - 1
            guard lastRow >= 0 else {
                self.historyTable.setContentOffset(CGPoint(x: 0,
                                                           y: self.historyTable.contentSize.height),
                                                   animated: animation)
                return
            }
            
            let indexPath = IndexPath(row: lastRow, section: lastSections)
            self.historyTable.scrollToRow(at: indexPath, at: .top, animated: animation)
        }
    }
    
    func updataSesame2UI()  {
        if let currentDegree = viewModel.currentDegree() {
            sesameCircle.refreshUI(newPointerAngle: CGFloat(currentDegree),
                                   lockColor: viewModel.lockColor)
        } else {
            sesameCircle.refreshUI(newPointerAngle: CGFloat(0.0),
                                   lockColor: viewModel.lockColor)
        }
        Locker.setBackgroundImage(UIImage.CHUIImage(named: viewModel.lockImage), for: .normal)
    }

    @objc private func handleRightBarButtonTapped(_ sender: Any) {
        viewModel.rightBarButtonTapped()
    }
    
    @objc private func handleLeftBarButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func lockButtonTapped(_ sender: UIButton) {
        isNeedScrollToBottom = true
        viewModel.lockButtonTapped()
    }
    
    deinit {
        L.d("Sesame22RoomMainViewController deinit")
    }
}

// MARK: - TableView DataSource Delegate
extension Sesame2HistoryViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var identifier = ""
        if indexPath.section == 0, indexPath.row == 0, canRefresh {
            identifier = "Sesame2HistoryLoadingTableViewCell"
        } else {
            identifier = viewModel.cellIdentifierForIndexPath(indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        if cell as? Sesame2HistoryCell != nil {
            let cellViewModel = self.viewModel.cellViewModelForIndexPath(indexPath)
            (cell as! Sesame2HistoryCell).viewModel = cellViewModel
        } else if cell as? Sesame2HistoryLoadingTableViewCell != nil {
            let cellViewModel = self.viewModel.cellViewModelForIndexPath(indexPath)
            (cell as! Sesame2HistoryLoadingTableViewCell).viewModel = cellViewModel
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") else {
            return UITableViewHeaderFooterView()
        }
        headerView.tintColor = UIColor.sesame2Gray

        if let label = headerView.subviews.filter({ $0.accessibilityIdentifier == "header label" }).first as? UILabel {
            label.text = viewModel.titleForHeaderInSection(section)
            headerView.bringSubviewToFront(headerView)
        } else {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.accessibilityIdentifier = "header label"
            label.text = viewModel.titleForHeaderInSection(section)
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
        if !isFirstTimeEnterTheView,
            (tableView.isDragging || tableView.isDecelerating || tableView.isTracking),
            indexPath.section == 0,
            indexPath.row == 0,
            isLoadingContent == false {
            startRefresh()
        }
    }
    
    @objc
    func startRefresh() {
        if canRefresh {
            L.d("😀 can refresh")
            canRefresh = false
            isNeedScrollToBottom = false
            refresh(self)
        } else {
            L.d("😀 can't refresh")
        }
    }
    
    @objc func refresh(_ sender: AnyObject) {
        self.viewModel.loadMore()
    }
    
    func refreshToBottom() {
        historyTable.reloadData()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.scrollToBottomWithAnimation(false)
//        }
    }
    
    func reloadContent() {
        canRefresh = viewModel.hasMoreData
        isLoadingContent = true
        historyTable.reloadData()
        if isNeedScrollToBottom == true {
            L.d("🔔","***刷新***")
            refreshToBottom()
            isLoadingContent = false
        } else {
            historyTable.layer.layoutIfNeeded()
            if isScrollToTopTapped == true {
               isScrollToTopTapped = false
            }
            let indexPath = self.viewModel.firstIndexPathBeforeUpdate()
            historyTable.scrollToRow(at: indexPath, at: .top, animated: false)
            isLoadingContent = false
        }
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if canRefresh {
            isScrollToTopTapped = true
            addRefreshControlIndicator()
            startRefresh()
        }
        return true
    }
}
