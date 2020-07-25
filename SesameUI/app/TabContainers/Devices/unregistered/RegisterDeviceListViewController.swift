//
//  RegisterDeviceList.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/9.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import SesameSDK

public final class RegisterDeviceListViewController: CHBaseViewController {

    var viewModel: RegisterDeviceListViewModel!
    
    @IBOutlet weak var backMenuBtn: UIButton!
    @IBOutlet weak var deviceTableView: UITableView!
    @IBAction func backClick(_ sender: Any) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion:nil)
        }
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.viewDidDisappear()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "RegisterDeviceListViewModel should not be nil.")
        
        viewModel.statusUpdated = { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            executeOnMainThread {
                switch status {
                case .loading:
                    ViewHelper.showLoadingInView(view: strongSelf.view)
                case .received:
                    strongSelf.deviceTableView.reloadData()
                case .finished(let result):
                    ViewHelper.hideLoadingView(view: strongSelf.view)
                    switch result {
                    case .success(_):
                        strongSelf.deviceTableView.reloadData()
                    case .failure(let error):
                        strongSelf.view.makeToast(error.errorDescription())
                    }
                }
            }
        }
        
        deviceTableView.tableFooterView = UIView(frame: .zero)
        backMenuBtn.setImage( UIImage.SVGImage(named: viewModel.backButtonImage), for: .normal)
        
        deviceTableView.rowHeight = UITableView.automaticDimension
        deviceTableView.estimatedRowHeight = 120
        deviceTableView.rowHeight = 120
    }
    
    deinit {
        L.d("RegisterDeviceListViewController deinit")
    }
}

extension RegisterDeviceListViewController: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRows = viewModel.numberOfRows
        if numberOfRows == 0 {
            tableView.setEmptyMessage(viewModel.emptyMessage)
        } else {
            tableView.restore()
        }
        return numberOfRows
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RegisterCell", for: indexPath) as! RegisterCell
        let cellViewModel = viewModel.registerCellModelForRow(indexPath.row)
        cell.viewModel = cellViewModel
        cell.ssi.textColor = (indexPath.row == 0) ? .sesame2Green : .gray
        cell.statusLabel.text = cellViewModel.currentStatus()
        // TODO: Uncomment when firmware is ready
//        cell.delegate = self
//        cell.dfuButton.setTitle(viewModel.dfuActionText, for: .normal)
//        cell.firmwareVersionLabel.text = viewModel.firmwareVersionForDeviceAtIndexPath(indexPath)
        return cell
    }
    
}

extension RegisterDeviceListViewController: RegisterCellDelegate {
    
    func dfuForCell(_ cell: UITableViewCell) {
        // TODO: Uncomment when firmware is ready
//        guard let indexPath = deviceTableView.indexPath(for: cell) else {
//            return
//        }
//
//        let check = UIAlertAction
//                   .addAction(title: viewModel.dfuActionText,
//                              style: .destructive) { (action) in
//                               let progressIndicator = TemporaryFirmwareUpdateClass(self) { success in
//
//                               }
//                               progressIndicator.dfuInitialized {
//                                   self.viewModel.cancelDFU()
//                               }
//                                self.viewModel.dfuDeviceAtIndexPath(indexPath, observer: progressIndicator)
//               }
//        UIAlertController.showAlertController(view,
//                                              style: .actionSheet,
//                                              actions: [check])
    }
}

extension RegisterDeviceListViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectCellAtRow(indexPath.row)
    }
}
