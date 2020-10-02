//
//  Sesame2ListViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

class Sesame2ListViewController: CHBaseTableViewController {
    
    // MARK: - Cell controllers
    var cellControllers = [Sesame2ListCellController]()
    
    // MARK: - UI components
    lazy var popUpMenuControl: PopUpMenuControl = {
        let y = UIApplication.shared.statusBarFrame.height + 44
        let frame = CGRect(x: 0, y: y, width: view.bounds.width, height: view.bounds.height - y)
        let popUpMenuControl = PopUpMenuControl(frame: frame)
        popUpMenuControl.delegate = self
        return popUpMenuControl
    }()
    var refreshControl: UIRefreshControl = UIRefreshControl()
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            self.navigationController?.navigationBar.standardAppearance.shadowColor = .clear
        } else {
            // Fallback on earlier versions
        }

        tableView.estimatedRowHeight = 120
        tableView.rowHeight = 120
        tableView.separatorStyle = .none
        refreshControl.attributedTitle = NSAttributedString(string: "co.candyhouse.sesame-sdk-test-app.PullToRefresh".localized)
        refreshControl.addTarget(self, action: #selector(getSesame2s), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        let rightButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: "icons_outlined_addoutline"),
                                              style: .done,
                                              target: self,
                                              action: #selector(handleRightBarButtonTapped(_:)))
        navigationItem.rightBarButtonItem = rightButtonItem
        
        tableView.register(UINib(nibName: "Sesame2ListCell", bundle: nil),
                           forCellReuseIdentifier: "Sesame2ListCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
            executeOnMainThread {
                self.refreshControl.beginRefreshing()
                let offsetPoint = CGPoint.init(x: 0, y: -self.refreshControl.frame.size.height)
                self.tableView.setContentOffset(offsetPoint, animated: true)
            }
        }
        getSesame2s()
    }
    
    // MARK: - getSesame2s
    @objc func getSesame2s() {
        CHDeviceManager.shared.getSesame2s { result in
            self.refreshControl.endRefreshing()
            switch result {
            case .success(let sesame2s):
                let sortedSesame2s = sesame2s.data.sorted(by: {
                    $0.compare($1)
                })
                self.cellControllers = sortedSesame2s.map {
                    return Sesame2ListCellController(sesame2: $0, navigationController: self.navigationController!)
                }
                
                self.reloadTableView()
                WatchKitFileTransfer.transferKeysToWatch()
            case .failure(_):
                break
            }
        }
    }
    
    // MARK: reloadTableView
    func reloadTableView() {
        let isEmpty = cellControllers.isEmpty
        notContentView.isHidden = isEmpty ? false : true
        tableView.isHidden = isEmpty ? true : false
        tableView.reloadData()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellControllers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellController = cellControllers[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Sesame2ListCell", for: indexPath) as! Sesame2ListCell
        cellController.cell = cell
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sesame = cellControllers[indexPath.row].sesame2
        navigateToSesame2History(sesame)
    }
    
    
    // MARK: - Navigation
    func navigateToSesame2History(_ sesame2: CHSesame2) {
        let sesame2HistoryViewController = Sesame2HistoryViewController.instanceWithSesame2(sesame2) {
            self.getSesame2s()
        }
        navigationController?.pushViewController(sesame2HistoryViewController,
                                                 animated: true)
    }
}

// MARK: - PopUpMenuDelegate
extension Sesame2ListViewController: PopUpMenuDelegate {
    
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
        popUpMenuControl.show(in: self.view)
    }
    
    func popUpMenu(_ menu: PopUpMenu, didTap item: PopUpMenuItem) {
        switch item.type {
        case .addDevices:
            presentRegisterSesame2ViewController()
        case .receiveKey:
            presentScanViewController()
        }
        hideMoreMenu(animated: false)
    }
    
    // MARK: Navigation
    func presentRegisterSesame2ViewController() {
        let registerSesame2ViewController = RegisterSesame2ViewController.instance { isRegisteredSesame2 in
            if isRegisteredSesame2 {
                self.getSesame2s()
            }
        }
        present(registerSesame2ViewController.navigationController!, animated: true, completion: nil)
    }
    
    func presentScanViewController() {
        let qrCodeScanViewController = QRCodeScanViewController.instance() { isReceivedKey in
            if isReceivedKey {
                self.getSesame2s()
            }
        }
        present(qrCodeScanViewController, animated: true, completion: nil)
    }
}

// MARK: - Designated initializer
extension Sesame2ListViewController {
    static func instance() -> Sesame2ListViewController {
        let sesame2ListViewController = Sesame2ListViewController(nibName: nil, bundle: nil)
        let navigationController = UINavigationController()
        navigationController.pushViewController(sesame2ListViewController, animated: false)
        return sesame2ListViewController
    }
}
