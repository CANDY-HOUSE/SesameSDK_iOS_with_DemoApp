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
    private var isFirstTimeEnterTheView = true
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
                        if strongSelf.canRefresh == false {
                            strongSelf.refreshControl.removeFromSuperview()
                        }
                        strongSelf.historyTable.reloadData()
                        if strongSelf.isNeedScrollToBottom == true {
                            strongSelf.refreshToBottom()
                        }
                    }
                case .failure(let error):
                    executeOnMainThread {
                        strongSelf.view.makeToast(error.errorDescription())
                    }
                }
            }
        }

        historyTable.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "header")
        viewModel.setFetchedResultsControllerDelegate(self)
        
        refreshControl.translatesAutoresizingMaskIntoConstraints = false
        historyTable.addSubview(refreshControl)
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
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if isFirstTimeEnterTheView == true {
            scrollToBottomWithAnimation(false)
        }
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
        viewModel.loadMore()
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
        viewModel.numberOfRowsInSection(section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = viewModel.cellIdentifierForIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        if let historyCell = cell as? Sesame2HistoryCell {
            configureCell(historyCell, atIndexPath: indexPath)
            return historyCell
        }
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        if cell as? Sesame2HistoryCell != nil {
            let cellViewModel = self.viewModel.cellViewModelForIndexPath(indexPath)
            (cell as! Sesame2HistoryCell).viewModel = cellViewModel
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < -5, !scrollView.isDragging {
            startRefresh()
        }
    }
    
    @objc
    func startRefresh() {
        if canRefresh {
            isNeedScrollToBottom = false
            canRefresh = false
            refresh(self)
        }
    }
    
    @objc func refresh(_ sender: AnyObject) {
        self.viewModel.loadMore()
    }
    
    func refreshToBottom() {
        historyTable.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.scrollToBottomWithAnimation()
        }
    }
}

// MARK: - FRC Delegate
extension Sesame2HistoryViewController: NSFetchedResultsControllerDelegate {
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        executeOnMainThread {
//            self.historyTable.beginUpdates()
//        }
    }
     
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        executeOnMainThread {
//            self.historyTable.endUpdates()
            self.canRefresh = self.viewModel.hasMoreData
            self.historyTable.reloadData()
            if self.isNeedScrollToBottom == true {
                self.refreshToBottom()
            }
//            if !self.historyTable.isTracking && !self.historyTable.isDragging && !self.historyTable.isDecelerating {
//                self.scrollToBottomWithAnimation(true)
//            }
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        executeOnMainThread {
//            let section = IndexSet(integer: sectionIndex)
//
//            switch type {
//            case .delete:
//                self.historyTable.deleteSections(section, with: .automatic)
//            case .insert:
//                self.historyTable.insertSections(section, with: .automatic)
//            case .move:
//                break
//            case .update:
//                break
//            @unknown default:
//                break
//            }
        }
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
//        executeOnMainThread {
//            switch (type) {
//            case .insert:
//                if let indexPath = newIndexPath as IndexPath? {
//                    self.historyTable.insertRows(at: [indexPath], with: .fade)
//                }
//            case .delete:
//                if let indexPath = indexPath as IndexPath? {
//                    self.historyTable.deleteRows(at: [indexPath], with: .fade)
//                }
//            case .update:
//                if let indexPath = indexPath as IndexPath? {
//                    if let cell = self.historyTable.cellForRow(at: indexPath) as? Sesame2HistoryCell {
//                        self.configureCell(cell, atIndexPath: indexPath)
//                    }
//                }
//            case .move:
//                if let indexPath = indexPath as IndexPath? {
//                    self.historyTable.deleteRows(at: [indexPath], with: .fade)
//                }
//
//                if let newIndexPath = newIndexPath as IndexPath? {
//                    self.historyTable.insertRows(at: [newIndexPath], with: .fade)
//                }
//            @unknown default:
//                break
//            }
//        }
        
    }
}
