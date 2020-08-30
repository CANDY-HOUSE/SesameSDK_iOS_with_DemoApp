//
//  WifiSelectionTableViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

class WifiSelectionTableViewController: UITableViewController {
    
    var viewModel: WifiSelectionTableViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "WifiSelectionTableViewModel should not be nil")
        
        viewModel.statusUpdated = { [weak self] status in
            switch status {
            case .loading:
                self?.view.makeToast("Scanning WiFi")
            case .update(_):
                self?.tableView.reloadData()
            case .finished(let result):
                break
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return viewModel.numberOfRows()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellViewModel = viewModel.cellViewModelAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "WifiSelectionTableViewCell", for: indexPath) as! WifiSelectionTableViewCell
        cell.viewModel = cellViewModel
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ssid = viewModel.ssidForIndexPath(indexPath)
        
        let alertController = UIAlertController(title: ssid,
                                                message: "Please enter the wifi password",
                                                preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "WiFi password"
            textField.text = "Power0fDreams!"
            textField.isSecureTextEntry = false
        }
        
        let action = UIAlertAction(title: "OK", style: .default) { [weak alertController, weak self] _ in
            if let textField = alertController?.textFields?[0] {
                self?.viewModel.didSelectRowAtIndexPath(indexPath,
                                                        password: textField.text!)
            }
            
        }
        alertController.addAction(action)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func passwordProvider() -> String {
        ""
    }
}
