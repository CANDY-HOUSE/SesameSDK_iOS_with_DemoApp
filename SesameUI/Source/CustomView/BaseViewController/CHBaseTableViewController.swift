//
//  CHBaseTableViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

private enum Constant {
    static let noContentView = "noContentView"
}

class CHBaseTableViewController: CHBaseViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - UI Components
    var tableView = UITableView(frame: .zero, style: .plain)
    var noContentView: UITableView {
        noContentViewController.tableView
    }
    private let noContentViewController = NoContentView(style: .plain)
    var noContentText: String = "" {
        didSet {
            noContentViewController.noContentText = noContentText
        }
    }
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        if tableView.dataSource == nil {
            tableView.dataSource = self
        }
        if tableView.delegate == nil {
            tableView.delegate = self
        }
        
        view.addSubview(tableView)
        
        addChild(noContentViewController)
        view.addSubview(noContentViewController.view)
        noContentViewController.view.autoPinEdgesToSuperview()
        noContentViewController.didMove(toParent: self)
        noContentViewController.tableView.reloadData()
        
        tableView.autoPinEdgesToSuperview()
        
        let isEmpty = tableView.numberOfSections == 0 ? true : false
        tableView.isHidden = isEmpty ? true : false
        
        noContentText = "".localized
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell()
    }
}

private class NoContentView: UITableViewController {
    
    var noContentText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constant.noContentView)
        tableView.showsVerticalScrollIndicator = false
        tableView.isScrollEnabled = false
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constant.noContentView, for: indexPath)
        cell.textLabel?.text = noContentText
        cell.textLabel?.textAlignment = .center
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        view.frame.height
    }
}
