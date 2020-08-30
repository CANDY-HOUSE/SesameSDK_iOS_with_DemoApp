//
//  RegisterWifiModule2ViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import CoreLocation

class RegisterWifiModule2ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var dismissButton: UIButton! {
        didSet {
            dismissButton.setTitle("", for: .normal)
            dismissButton.setImage( UIImage.SVGImage(named: "icons_filled_close"), for: .normal)
        }
    }
    
    let locationManager = CLLocationManager()
    var viewModel: RegisterWifiModule2ViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(viewModel != nil, "RegisterDeviceListViewModel should not be nil.")
        locationManager.requestWhenInUseAuthorization()
        tableView.dataSource = self
        tableView.delegate = self
        
        viewModel.statusUpdated = { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            executeOnMainThread {
                switch status {
                case .loading:
                    ViewHelper.showLoadingInView(view: strongSelf.view)
                case .update(let action):
                    if let action = action as? RegisterWifiModule2ViewModel.Action,
                        action == RegisterWifiModule2ViewModel.Action.dfu {
//                        strongSelf.dfuSelectedDevice()
                    } else {
                        strongSelf.tableView.reloadData()
                    }
                    
                case .finished(let result):
                    ViewHelper.hideLoadingView(view: strongSelf.view)
                    switch result {
                    case .success(let type):
                        if let type = type as? RegisterWifiModule2ViewModel.Complete,
                            type == .wifiSetup {
                            strongSelf.view.makeToast("WiFi setup succeed!")
                        } else {
                            strongSelf.tableView.reloadData()
                        }
                    case .failure(let error):
                        strongSelf.view.makeToast(error.errorDescription())
                    }
                }
            }
        }
        
        tableView.tableFooterView = UIView(frame: .zero)
        //backMenuBtn.setImage( UIImage.SVGImage(named: viewModel.backButtonImage), for: .normal)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = 120
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.disconnect()
    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRows = viewModel.numberOfRowsInSection(section)
        if numberOfRows == 0 {
            tableView.setEmptyMessage(viewModel.emptyMessage)
        } else {
            tableView.restore()
        }
        return numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellViewModel = viewModel.cellViewModelForRowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "RegisterWifiModule2Cell", for: indexPath) as! RegisterWifiModule2Cell
        cell.viewModel = cellViewModel
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectCellAtIndexPath(indexPath)
    }
}
