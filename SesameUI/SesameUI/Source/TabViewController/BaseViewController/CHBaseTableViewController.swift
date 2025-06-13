//
//  CHBaseTableViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//
//  逐步废弃。请使用 CHTableProxy 。
//  此类别使用了两层 tableview 实现 emptyView。会造成刷新时各种问题。
//

import UIKit

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
    var noContentDetailText: String = "" {
        didSet {
            noContentViewController.noContentDetailText = noContentDetailText
        }
    }
    
    func reloadTableView(isEmpty: Bool) {
        noContentView.isHidden = isEmpty ? false : true
        tableView.isHidden = isEmpty ? true : false
        tableView.reloadData()
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
        
        tableView.autoPinLeading()
        tableView.autoPinTrailing()
        tableView.autoPinTopToSafeArea()
        tableView.autoPinBottom()
        
        let isEmpty = tableView.numberOfSections == 0 ? true : false
        tableView.isHidden = isEmpty ? true : false
        
        noContentText = "".localized
        
        if #available(iOS 15.0, *) {//15 特別有這格屬性。列表的header
            tableView.sectionHeaderTopPadding = 0// 影響範圍。歷史頁面上方的日期header 
        }
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
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
    var noContentDetailText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "noContentView")
        tableView.showsVerticalScrollIndicator = false
        tableView.isScrollEnabled = false
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        noContentDetailText == "" ? 1 : 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "noContentView", for: indexPath)
        cell.textLabel?.text = indexPath.row == 0 ? noContentText : noContentDetailText
        cell.textLabel?.textAlignment = indexPath.row == 0 ? .center : .left
        if noContentDetailText != "" {
            cell.textLabel?.autoPinWidth(constant: -50)
            cell.textLabel?.autoPinCenterX()
            if indexPath.row == 0 {
                cell.textLabel?.autoPinBottom(constant: -10)
                cell.textLabel?.font = UIFont.systemFont(ofSize: UIFont.labelFontSize)
                cell.textLabel?.textColor = UIColor.black
            } else {
                cell.textLabel?.autoPinTop()
                cell.textLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
                cell.textLabel?.textColor = UIColor.placeHolderColor
            }
        }
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if noContentDetailText == "" {
            return view.frame.height
        } else {
            if indexPath.row == 0 {
                return view.frame.height * 2/5
            } else {
                return view.frame.height * 3/5
            }
        }
    }
}
