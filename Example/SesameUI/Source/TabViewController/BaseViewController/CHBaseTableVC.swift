//
//  CHBaseTableVC.swift
//  SesameUI
//
//  Created by tse on 2023/5/25.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

class CHBaseTableVC: CHBaseViewController, UITableViewDataSource, UITableViewDelegate {

    var tableView = UITableView(frame: .zero, style: .plain)
    func reloadTableView() {
        executeOnMainThread{ [self] in
            tableView.reloadData()
            tableView.backgroundView?.isHidden = (tableView(tableView, numberOfRowsInSection: 0) == 0 ) ? false  : true
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.autoPinLeading()
        tableView.autoPinTrailing()
        tableView.autoPinTopToSafeArea()
        tableView.autoPinBottom()
    }

    func numberOfSections(in tableView: UITableView) -> Int {  return 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 0 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell()
    }

    func setupEmptyDataView(_ title: String) {
        let emptyDataView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        let emptyDataLabel = UILabel()
        emptyDataLabel.text = title
        emptyDataLabel.textColor = UIColor.placeHolderColor
        emptyDataLabel.textAlignment = .center
        emptyDataLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        emptyDataLabel.numberOfLines = 0 //允許換行
        emptyDataLabel.lineBreakMode = .byWordWrapping //以單字換行
        emptyDataLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyDataView.addSubview(emptyDataLabel)
        NSLayoutConstraint.activate([
            emptyDataLabel.centerXAnchor.constraint(equalTo: emptyDataView.centerXAnchor),
            emptyDataLabel.centerYAnchor.constraint(equalTo: emptyDataView.centerYAnchor, constant: -50),
            emptyDataLabel.leadingAnchor.constraint(equalTo: emptyDataView.leadingAnchor, constant: 20),
            emptyDataLabel.trailingAnchor.constraint(equalTo: emptyDataView.trailingAnchor, constant: -20)
        ])
        tableView.backgroundView = emptyDataView
    }

}

