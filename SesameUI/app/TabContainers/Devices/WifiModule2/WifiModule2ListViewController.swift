//
//  WifiModule2ListViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

class WifiModule2ListViewController: CHBaseViewController {
    
    var refreshControl: UIRefreshControl = UIRefreshControl()
    @IBOutlet var deviceTableView: UITableView!
    
    var viewModel: WifiModule2ListViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "ViewModel shouldn't be nil.")
        viewModel.statusUpdated = { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            switch status {
            case .loading:
                executeOnMainThread {
                    ViewHelper.showLoadingInView(view: strongSelf.view)
                }
            case .update:
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: strongSelf.view)
                    strongSelf.updateTableView()
                }
            case .finished:
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: strongSelf.view)
                    strongSelf.updateTableView()
                }
            }
        }
        
        deviceTableView.rowHeight = UITableView.automaticDimension
        deviceTableView.estimatedRowHeight = 110
        deviceTableView.rowHeight = 110
        
        refreshControl.attributedTitle = NSAttributedString(string: "co.candyhouse.sesame-sdk-test-app.PullToRefresh".localized)
        refreshControl.addTarget(self, action: #selector(pullTorefresh), for: .valueChanged)
        deviceTableView.addSubview(refreshControl)
        deviceTableView.tableFooterView = UIView(frame: .zero)
        
        viewModel.getWifiModule2s()
    }
    
    @objc func pullTorefresh(sender:AnyObject) {
        viewModel.loadLocalDevices()
    }
    
    func updateTableView() {
        self.deviceTableView.reloadData()
        
        if self.viewModel.numberOfRows() == 0 {
            self.deviceTableView.setEmptyMessage("co.candyhouse.sesame-sdk-test-app.NoDevices".localized)
        } else {
            self.deviceTableView.restore()
        }
    }
    
    @IBAction func testModeChange(_ sender: Any) {
        self.deviceTableView.reloadData()
    }
}

extension WifiModule2ListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellViewModel = viewModel.cellViewModelAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "WifiModule2ListCell", for: indexPath) as! WifiModule2ListCell
        cell.viewModel = cellViewModel
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            viewModel.resetWifiModule2AtIndexPath(indexPath)
        }
    }
}
