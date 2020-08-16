//
//  RegisterWifiModule2ViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
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
        
        Topic
            .updateTopic("$aws/things/testss2/shadow/name/topic_WM2_publish/update")
            .subscribe { result in
                switch result {
                case .success(let content):
                    executeOnMainThread {
                        self.view.makeToast(content)
                    }
                case .failure(let error):
                    executeOnMainThread {
                        self.view.makeToast(error.errorDescription())
                    }
                }
        }
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
        
        guard let wifiSSID = UIDevice.current.WiFiSSID else {
            if CLLocationManager.authorizationStatus() == .denied ||
                !CLLocationManager.locationServicesEnabled() ||
                CLLocationManager.authorizationStatus() == .notDetermined {
                let alertController = UIAlertController(title: "Permisson Not determind", message: "Go to app setting and grant the location access permission", preferredStyle: .alert)
                let action = UIAlertAction(title: "Go", style: .default) { _ in
                    let url = URL(string: UIApplication.openSettingsURLString)
                    UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                }
                alertController.addAction(action)
                let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alertController.addAction(cancel)
            }
            L.d("Could not get WiFiSSID: authorizationStatus \(CLLocationManager.authorizationStatus())")
            return
        }
        
        let alertController = UIAlertController(title: wifiSSID,
                                                message: "Please enter the wifi password",
                                                preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "WiFi password"
            textField.isSecureTextEntry = true
        }
        
        let action = UIAlertAction(title: "OK", style: .default) { [weak alertController, weak self] _ in
            if let textField = alertController?.textFields?[0] {
                self?.viewModel.didSelectCellAtRow(indexPath.row,
                                                   ssid: wifiSSID,
                                                   password: textField.text!)
            }
            
        }
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
        
    }
}
