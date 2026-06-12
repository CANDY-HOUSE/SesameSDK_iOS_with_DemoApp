//
//  CHBaseTableVC.swift
//  SesameUI
//  已废弃，请使用 CHTableProxy
//  Created by tse on 2023/5/25.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

class CHBaseTableVC: CHBaseViewController, UITableViewDataSource, UITableViewDelegate {

    var tableView = UITableView(frame: .zero, style: .plain)
    private let fixedStatusViewHeight: CGFloat = 64
    private var fixedStatusTopInset: CGFloat = 0
    private var floatingTipTopInset: CGFloat = 0
    private weak var managedFloatingTipView: UIView?

    private lazy var fixedStatusView: CHUIPlainSettingView = {
        let view = CHUIViewGenerator.plain()
        view.backgroundColor = .lockRed
        view.title = ""
        view.setColor(.white)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshFixedTableStatusViewIfNeeded()
    }
    
    override func didBecomeActive() {
        super.didBecomeActive()

        refreshFixedTableStatusViewIfNeeded()
    }
    
    func setupFixedTableStatusView() {
        guard fixedStatusView.superview == nil else {
            return
        }

        view.addSubview(fixedStatusView)

        let heightConstraint = fixedStatusView.heightAnchor.constraint(equalToConstant: fixedStatusViewHeight)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true

        NSLayoutConstraint.activate([
            fixedStatusView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            fixedStatusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fixedStatusView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        view.bringSubviewToFront(fixedStatusView)
    }
    
    func setFloatingTipView(_ floatingTipView: UIView, height: CGFloat) {
        managedFloatingTipView = floatingTipView
        floatingTipTopInset = height
        updateTableViewInsets()
    }
    
    private func updateTableViewInsets() {
        let topInset = fixedStatusTopInset + floatingTipTopInset

        tableView.contentInset = UIEdgeInsets(
            top: topInset,
            left: 0,
            bottom: 0,
            right: 0
        )

        tableView.scrollIndicatorInsets = tableView.contentInset

        managedFloatingTipView?.transform = CGAffineTransform(
            translationX: 0,
            y: fixedStatusTopInset
        )
    }
    
    @discardableResult
    func showFixedTableStatusViewIfNeeded(
        isUnlogined: Bool,
        statusTitle: String
    ) -> Bool {
        let shouldShow: Bool

        if CHBluetoothCenter.shared.scanning.bleStatus == .closed {
            fixedStatusView.title = "co.candyhouse.sesame2.bluetoothPoweredOff".localized
            shouldShow = true
        } else if isUnlogined {
            fixedStatusView.title = statusTitle
            shouldShow = true
        } else {
            shouldShow = false
        }

        fixedStatusView.isHidden = !shouldShow
        fixedStatusTopInset = shouldShow ? fixedStatusViewHeight : 0

        updateTableViewInsets()

        view.bringSubviewToFront(fixedStatusView)
        view.layoutIfNeeded()

        return shouldShow
    }
    
    func refreshFixedTableStatusViewIfNeeded() {
        // subclass override if needed
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
             // 使UILabel的左右边距保持20点的距离，这样可以确保UILabel的宽度在屏幕尺寸变化时能够正确地调整。如果文本长度超过UILabel的宽度，它应该会自动换行。
        ])
        tableView.backgroundView = emptyDataView
    }

}

