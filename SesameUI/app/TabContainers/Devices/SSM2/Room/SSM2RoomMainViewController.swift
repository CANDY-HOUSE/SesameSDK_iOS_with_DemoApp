//
//  SSM2RoomMainViewController.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/10/14.
//  Copyright © 2019 Cerberus. All rights reserved.
//


import UIKit
import SesameSDK
import CoreBluetooth
import CoreData

class SSM2RoomMainViewController: CHBaseViewController {
    
    var viewModel: SSM2RoomMainViewModel!

    @IBOutlet weak var historyTable: UITableView!
    @IBOutlet weak var sesameCircle: SesameCircle!
    @IBOutlet weak var Locker: UIButton!
    var refreshControl = UIActivityIndicatorView(style: .gray)
    
    @IBAction func lockButtonTapped(_ sender: UIButton) {
        viewModel.lockButtonTapped()
    }
    
    override func viewDidLoad() {
        super .viewDidLoad()
        assert(viewModel != nil, "SSM2RoomMainViewModel should not be nil.")
        
        let rightButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: "icons_filled_more"), style: .done, target: self, action: #selector(handleRightBarButtonTapped(_:)))
              navigationItem.rightBarButtonItem = rightButtonItem
        
        viewModel.statusUpdated = { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            switch status {
            case .loading:
                strongSelf.refreshControl.startAnimating()
            case .received:
                executeOnMainThread {
                    strongSelf.updataSSMUI()
                }
            case .finished(_):
                executeOnMainThread {
                    strongSelf.historyTable.reloadData()
                    strongSelf.hideLoadingIndicator()
                    strongSelf.refreshControl.stopAnimating()
                }
            }
        }

        refreshControl.translatesAutoresizingMaskIntoConstraints = false
        refreshControl.stopAnimating()
        historyTable.addSubview(refreshControl)
        
        let constraints = [
            refreshControl.centerXAnchor.constraint(equalTo: historyTable.centerXAnchor),
            refreshControl.topAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor,
                                                 constant: 2),
            refreshControl.widthAnchor.constraint(equalToConstant: 20),
            refreshControl.heightAnchor.constraint(equalToConstant: 20)
        ]
        NSLayoutConstraint.activate(constraints)

        viewModel.setFetchedResultsControllerDelegate(self)
        
        historyTable.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "header")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
        updataSSMUI()
        historyTable.reloadData()
        viewModel.pullDown()
        viewModel.viewWillAppear()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        title = viewModel.title
        scrollToBottom()
    }
    
    fileprivate func scrollToBottom() {
        executeOnMainThread {
            let lastSections = self.historyTable.numberOfSections - 1
            guard lastSections >= 0 else {
                self.historyTable.setContentOffset(CGPoint(x: 0,
                                                           y: self.historyTable.contentSize.height),
                                                   animated: true)
                return
            }
            
            let lastRow = self.historyTable.numberOfRows(inSection: lastSections) - 1
            guard lastRow >= 0 else {
                self.historyTable.setContentOffset(CGPoint(x: 0,
                                                           y: self.historyTable.contentSize.height),
                                                   animated: true)
                return
            }
            
            let indexPath = IndexPath(row: lastRow, section: lastSections)
            self.historyTable.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    func updataSSMUI()  {
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
    
    deinit {
        L.d("SSM2RoomMainViewController deinit")
    }
}

extension SSM2RoomMainViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRowsInSection(section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! SSM2HistoryCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: SSM2HistoryCell, atIndexPath indexPath: IndexPath) {
        let cellViewModel = viewModel.cellViewModelForIndexPath(indexPath)
        cell.viewModel = cellViewModel
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") else {
            return UITableViewHeaderFooterView()
        }
        headerView.tintColor = UIColor.sesameGray

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

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if refreshControl.isAnimating {
            showLoadingIndicator()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < -25,
            !refreshControl.isAnimating {
            refreshControl.startAnimating()
            showLoadingIndicator()
            refresh(self)
        }
    }
    
    func showLoadingIndicator() {
        executeOnMainThread {
            let offsetPoint = CGPoint(x: 0, y: -self.refreshControl.frame.maxY)
            self.historyTable.setContentOffset(offsetPoint, animated: true)
        }
    }
    
    func hideLoadingIndicator() {
        executeOnMainThread {
            self.historyTable.setContentOffset(CGPoint.zero, animated: true)
        }
    }
    
    @objc func refresh(_ sender: AnyObject) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.viewModel.pullDown()
        }
    }
}

extension SSM2RoomMainViewController: NSFetchedResultsControllerDelegate {
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        executeOnMainThread {
            self.historyTable.beginUpdates()
        }
    }
     
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        executeOnMainThread {
            self.historyTable.endUpdates()
            self.scrollToBottom()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        executeOnMainThread {
            let section = IndexSet(integer: sectionIndex)
            
            switch type {
            case .delete:
                self.historyTable.deleteSections(section, with: .automatic)
            case .insert:
                self.historyTable.insertSections(section, with: .automatic)
            case .move:
                break
            case .update:
                break
            @unknown default:
                break
            }
        }
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        executeOnMainThread {
            switch (type) {
            case .insert:
                if let indexPath = newIndexPath as IndexPath? {
                    self.historyTable.insertRows(at: [indexPath], with: .fade)
                }
            case .delete:
                if let indexPath = indexPath as IndexPath? {
                    self.historyTable.deleteRows(at: [indexPath], with: .fade)
                }
            case .update:
                if let indexPath = indexPath as IndexPath? {
                    if let cell = self.historyTable.cellForRow(at: indexPath) as? SSM2HistoryCell {
                        self.configureCell(cell, atIndexPath: indexPath)
                    }
                }
            case .move:
                if let indexPath = indexPath as IndexPath? {
                    self.historyTable.deleteRows(at: [indexPath], with: .fade)
                }

                if let newIndexPath = newIndexPath as IndexPath? {
                    self.historyTable.insertRows(at: [newIndexPath], with: .fade)
                }
            @unknown default:
                break
            }
        }
        
    }
}
