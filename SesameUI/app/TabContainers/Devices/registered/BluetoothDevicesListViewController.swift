//
//  BluetoothDevicesListViewController.swift
//  sesame-sdk-test-app
//
//  Created by Cerberus on 2019/08/05.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import UIKit
import CoreBluetooth
import SesameSDK
import UserNotifications
import WatchConnectivity

public class BluetoothDevicesListViewController: CHBaseViewController, UITableViewDelegate {
    
    @IBOutlet weak var testMode: UISwitch! {
        didSet {
            testMode.addTarget(self, action: #selector(BluetoothDevicesListViewController.testToggleSwitched), for: .valueChanged)
        }
    }
    @IBAction func testModeChange(_ sender: Any) {
        self.deviceTableView.reloadData()
    }

    var viewModel: BluetoothDevicesListViewModel!
    
    lazy var popUpMenuControl: PopUpMenuControl = {
        let y = Constants.statusBarHeight + 44
        let frame = CGRect(x: 0, y: y, width: view.bounds.width, height: view.bounds.height - y)
        let popUpMenuControl = PopUpMenuControl(frame: frame)
        popUpMenuControl.delegate = self
        return popUpMenuControl
    }()
    var refreshControl: UIRefreshControl = UIRefreshControl()
    @IBOutlet weak var deviceTableView: UITableView!

    public override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "ViewModel shouldn't be nil.")

        if #available(iOS 13.0, *) {
            self.navigationController?.navigationBar.standardAppearance.shadowColor = .clear
        } else {
            // Fallback on earlier versions
        }

        viewModel.statusUpdated = { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            switch status {
            case .loading:
                executeOnMainThread {
                    strongSelf.programmaticallyRefreshing()
                }
            case .received:
                executeOnMainThread {
                    strongSelf.refreshControl.endRefreshing()
                    strongSelf.notifyTable()
                }
            case .finished:
                executeOnMainThread {
                    strongSelf.refreshControl.endRefreshing()
                    strongSelf.notifyTable()
                }
            }
        }

        let rightButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: "icons_outlined_addoutline"),
                                              style: .done,
                                              target: self,
                                              action: #selector(handleRightBarButtonTapped(_:)))
        navigationItem.rightBarButtonItem = rightButtonItem
        

        
        testMode.isOn = viewModel.isTestModeOn
        
        deviceTableView.rowHeight = UITableView.automaticDimension
        deviceTableView.estimatedRowHeight = 110
        deviceTableView.rowHeight = 110
        
        #if DEBUG
        testMode.isHidden = false
        #else
        testMode.isHidden = true
        #endif

        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh".localStr)
        refreshControl.addTarget(self, action: #selector(pullTorefresh), for: .valueChanged)
        deviceTableView.addSubview(refreshControl)
        deviceTableView.tableFooterView = UIView(frame: .zero)
        deviceTableView.delegate = self
        viewModel.loadLocalDevices()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
            DispatchQueue.main.async {
                self.programmaticallyRefreshing()
            }
        }


        self.deviceTableView.reloadData()

        L.d("列表頁面 viewWillAppear")


    }
    
    
    func programmaticallyRefreshing() {
        refreshControl.beginRefreshing()
        let offsetPoint = CGPoint.init(x: 0, y: -refreshControl.frame.size.height)
        deviceTableView.setContentOffset(offsetPoint, animated: true)
    }
    
    @objc func testToggleSwitched() {
        viewModel.testSwitchToggled(isOn: testMode.isOn)
    }
    
    @objc func pullTorefresh(sender:AnyObject) {
        viewModel.loadLocalDevices()
    }
    
    @objc private func handleRightBarButtonTapped(_ sender: Any) {
        if self.popUpMenuControl.superview != nil {
            hideMoreMenu()
        } else {
            showMoreMenu()
        }
    }
    
    private func hideMoreMenu(animated: Bool = true) {
        popUpMenuControl.hide(animated: animated)
    }
    
    private func showMoreMenu() {
        //        refleshRoomBackTitle(name: "")
        popUpMenuControl.show(in: self.view)
    }
}

extension BluetoothDevicesListViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //        L.d("!@#: \(viewModel.numberOfRows)")
        return viewModel.numberOfRows
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SSMCell", for: indexPath) as! BluetoothDevicesCell
        let cellViewModel = viewModel.cellViewModelAt(indexPath)
        
        cell.viewModel = cellViewModel
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        L.d("didSelectRowAt !@#: \(indexPath)")
        viewModel.didSelectRowAt(indexPath)
    }
}



extension BluetoothDevicesListViewController {

    func notifyTable()  {
        DispatchQueue.main.async {
            self.deviceTableView.reloadData()
            if self.viewModel.numberOfRows == 0 {
                self.deviceTableView.setEmptyMessage("No Devices".localStr)
            } else {
                self.deviceTableView.restore()
            }
        }
    }
}

extension BluetoothDevicesListViewController: PopUpMenuDelegate {
    func popUpMenu(_ menu: PopUpMenu, didTap item: PopUpMenuItem) {
        viewModel.popUpMenuTappedOnItem(item)
        hideMoreMenu(animated: false)
    }
}
