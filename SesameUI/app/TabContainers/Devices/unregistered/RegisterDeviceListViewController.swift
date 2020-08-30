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
                case .update(let action):
                    if let action = action as? RegisterDeviceListViewModel.Action,
                        action == RegisterDeviceListViewModel.Action.dfu {
                        strongSelf.dfuSelectedDevice()
                    } else {
                        strongSelf.deviceTableView.reloadData()
                    }
                    
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
        cell.delegate = self
        return cell
    }
    
}

extension RegisterDeviceListViewController: RegisterCellDelegate {
    func dfuTapped(cell: UITableViewCell) {
        guard let indexPath = deviceTableView.indexPath(for: cell) else {
            return
        }
        dfuSelectedDevice(indexPath: indexPath)
    }
}

extension RegisterDeviceListViewController {
    
    func dfuSelectedDevice(indexPath: IndexPath? = nil) {
        
        guard let indexPath = indexPath ?? deviceTableView.indexPathForSelectedRow else {
            return
        }

        showChooseDFUModeTypeForIndexPath(indexPath)
    }
    
    func showChooseDFUModeTypeForIndexPath(_ indexPath: IndexPath) {
        let chooseDFUModeAlertController = UIAlertController(title: "co.candyhouse.sesame-sdk-test-app.dfu".localized,
                                                             message: "co.candyhouse.sesame-sdk-test-app.SesameOSUpdate".localized,
                                                preferredStyle: .actionSheet)
        let actionSheetApplicationDFU = UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.application".localized, style: .default) { _ in
            self.showApplicaitonDFUAlertForIndexPath(indexPath)
        }
        
        let actionSheetBootloaderDFU = UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.bootloader".localized, style: .default) { _ in
            self.showBootloaderDFUAlertForIndexPath(indexPath)
        }
        
        chooseDFUModeAlertController.addAction(actionSheetApplicationDFU)
        chooseDFUModeAlertController.addAction(actionSheetBootloaderDFU)
        chooseDFUModeAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(chooseDFUModeAlertController, animated: true, completion: nil)
    }
    
    func showApplicaitonDFUAlertForIndexPath(_ indexPath: IndexPath) {
        let dfu = UIAlertAction
            .addAction(title: viewModel.dfuActionText,
                       style: .destructive) { (action) in
                        let progressIndicator = TemporaryFirmwareUpdateClass(self) { success in
                            
                        }
                        progressIndicator.dfuInitialized {
                            self.viewModel.cancelDFU()
                        }
                        self.viewModel.dfuApplicationDeviceAtIndexPath(indexPath, observer: progressIndicator)
        }
        let alertController = UIAlertController(title: "co.candyhouse.sesame-sdk-test-app.application_dfu".localized,
                                                message: viewModel.applicationDfuFileName(),
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Cancel".localized, style: .cancel, handler: nil)
        alertController.addAction(dfu)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
    }
    
    func showBootloaderDFUAlertForIndexPath(_ indexPath: IndexPath) {
        let dfu = UIAlertAction
            .addAction(title: viewModel.dfuActionText,
                       style: .destructive) { (action) in
                        let progressIndicator = TemporaryFirmwareUpdateClass(self) { success in
                            
                        }
                        progressIndicator.dfuInitialized {
                            self.viewModel.cancelDFU()
                        }
                        self.viewModel.dfuBootloaderDeviceAtIndexPath(indexPath, observer: progressIndicator)
        }
        let alertController = UIAlertController(title: "co.candyhouse.sesame-sdk-test-app.bootloader_dfu".localized,
                                                message: viewModel.bootloaderDfuFileName(),
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Cancel".localized, style: .cancel, handler: nil)
        alertController.addAction(dfu)
        alertController.addAction(cancel)
        present(alertController, animated: true, completion: nil)
    }
}

extension RegisterDeviceListViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.didSelectCellAtRow(indexPath.row)
    }
}
