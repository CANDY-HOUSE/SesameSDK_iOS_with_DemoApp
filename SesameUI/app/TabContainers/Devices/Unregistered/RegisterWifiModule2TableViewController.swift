//
//  RegisterWifiModule2ViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

class RegisterWifiModule2ViewController: UIViewController {

    var viewModel: RegisterWifiModule2ViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
                    case .success(_):
                        strongSelf.tableView.reloadData()
                    case .failure(let error):
                        strongSelf.view.makeToast(error.errorDescription())
                    }
                }
            }
        }
        
        tableView.tableFooterView = UIView(frame: .zero)
        //backMenuBtn.setImage( UIImage.SVGImage(named: viewModel.backButtonImage), for: .normal)
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = 100
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section) + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let closeButtonCell = tableView.dequeueReusableCell(withIdentifier: "CloseButtonCell", for: indexPath) as! CloseButtonCell
            closeButtonCell.delegate = self
            return closeButtonCell
        } else {
            let indexPath = IndexPath(row: indexPath.row - 1,
                                      section: indexPath.section)
            let cellViewModel = viewModel.cellViewModelForRowAtIndexPath(indexPath)
            let cell = tableView.dequeueReusableCell(withIdentifier: "RegisterWifiModule2Cell", for: indexPath) as! RegisterWifiModule2Cell
            cell.viewModel = cellViewModel
            return cell
        }
    }

}

extension RegisterWifiModule2ViewController: CloseButtonCellDelegate {
    func closeDidTapped() {
        dismiss(animated: true, completion: nil)
    }
}
