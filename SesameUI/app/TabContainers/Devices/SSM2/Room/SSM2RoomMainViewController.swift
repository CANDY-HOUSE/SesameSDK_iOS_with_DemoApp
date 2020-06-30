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

class SSM2RoomMainViewController: CHBaseViewController {

    var viewModel: SSM2RoomMainViewModel!

    @IBOutlet weak var historyTable: UITableView!
    @IBOutlet weak var sesameCircle: SesameCircle!
    @IBOutlet weak var Locker: UIButton!
    
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
                break
            case .received:
                executeOnMainThread {
                    strongSelf.updataSSMUI()
                    strongSelf.moveToBottom(true)
                }
            case .finished(_):
                break
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super .viewWillAppear(animated)
        updataSSMUI()
        viewModel.getHistory()
        DispatchQueue(label: "sesameSDK.API", qos: .default, attributes: .concurrent).async {
            self.moveToBottom()
        }
        
        viewModel.viewWillAppear()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        title = viewModel.title
    }
    
    func updataSSMUI()  {
//        L.d("歷史ＳＳＭ狀態", sesame.deviceStatus.description())
        if let currentDegree = viewModel.currentDegree() {
            sesameCircle.refreshUI(newPointerAngle: CGFloat(currentDegree),
                                   lockColor: viewModel.lockColor)
        } else {
            sesameCircle.refreshUI(newPointerAngle: CGFloat(0.0),
                                   lockColor: viewModel.lockColor)
        }
        
        Locker.setBackgroundImage(UIImage.CHUIImage(named: viewModel.lockImage), for: .normal)
    }
    
    func moveToBottom(_ scroll: Bool = false) {
        DispatchQueue.main.async {
            self.historyTable.reloadData()
//            if let lastIndex = self.viewModel.lastIndex() {
//                self.historyTable.scrollToRow(at: lastIndex, at: .bottom, animated: scroll)
//            }
        }
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

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryHeader") as! SSM2HistoryHeaderCell
        let headerViewModel = viewModel.headerViewModelForSection(section)
        cell.viewModel = headerViewModel
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRowsInSection(section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! SSM2HistoryCell
        let cellViewModel = viewModel.cellViewModelForIndexPath(indexPath)
//        let history = historyGroup[indexPath.section][indexPath.row]
        //todo  remove seld will  happen
        //todo  Thread 1: Fatal error: Index out of range
        cell.viewModel = cellViewModel

        return cell
    }
}

