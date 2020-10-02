//
//  CHBaseTableViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

class CHBaseTableViewController: CHBaseViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - UI Components
    let tableView = UITableView(frame: .zero, style: .plain)
    let notContentView = UIStackView()
    let noDeviceLabel = UILabel(frame: .zero)
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        notContentView.axis = .vertical
        notContentView.alignment = .fill
        notContentView.distribution = .fill
        
        noDeviceLabel.text = "No Devices"
        noDeviceLabel.textAlignment = .center
        notContentView.addArrangedSubview(noDeviceLabel)
        
        view.addSubview(tableView)
        view.addSubview(notContentView)
        
        tableView.autoPinEdgesToSuperview()
        notContentView.autoPinEdgesToSuperview()
        
        let isEmpty = tableView.numberOfSections == 0 ? true : false
        tableView.isHidden = isEmpty ? true : false
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
