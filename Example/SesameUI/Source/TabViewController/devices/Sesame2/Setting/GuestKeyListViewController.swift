//
//  GuestKeyListViewController.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/01/05.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

private let cellId = "cell"

class GuestKeyListViewController : CHBaseTableViewController {

    var device: CHSesameLock!

    var guestKeys = [CHGuestKey]()
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var noContentRefreshControl: UIRefreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()

        let dismissButton = UIButton(type: .custom)
        dismissButton.setImage(UIImage.SVGImage(named: "icons_filled_close"), for: .normal)
        let dismissButtonItem = UIBarButtonItem(customView: dismissButton)
        dismissButtonItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        dismissButtonItem.customView?.heightAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButtonItem.customView?.widthAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)

        navigationItem.rightBarButtonItem = dismissButtonItem

        getGuestKeys()

        tableView.register(GuestKeyListCell.self, forCellReuseIdentifier: cellId)
        tableView.tableFooterView = UIView()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance.backgroundColor = .white
        } else {
            navigationController?.navigationBar.barTintColor = .white
        }
    }

    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }

    func getGuestKeys() {
        ViewHelper.showLoadingInView(view: self.view)
        device.getGuestKeys { result in
            executeOnMainThread {
                if case let .success(guestKey) = result {
                    self.guestKeys = guestKey.data
                    self.reloadTableView(isEmpty: self.guestKeys.isEmpty)
                }
                ViewHelper.hideLoadingView(view: self.view)
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guestKeys.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! GuestKeyListCell
        let guestKey = guestKeys[indexPath.row]
        cell.textLabel?.text = guestKey.keyName
        cell.detailTextLabel?.text = String(guestKey.guestKeyId.suffix(4))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let guestKey = self.guestKeys[indexPath.row]
        presentCHAlertWithPlaceholder(title: "co.candyhouse.sesame2.modifyGuestKeyTag".localized, placeholder: guestKey.keyName, hint: "") { newValue in
            ViewHelper.showLoadingInView(view: self.view)
            self.device.updateGuestKey(guestKey.guestKeyId, name: newValue) { result in
                executeOnMainThread {
                    if case .success(_) = result {
                        ViewHelper.hideLoadingView(view: self.view)
                        self.guestKeys[indexPath.row].keyName = newValue
                        self.tableView.reloadData()
                        tableView.deselectRow(at: indexPath, animated: true)
                    }
                }
            }
        } cancelHandler: {
            executeOnMainThread {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let guestKeyId = self.guestKeys[indexPath.row].guestKeyId
            guestKeys.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.device.removeGuestKey(guestKeyId) { result in
                if case let .failure(error) = result {
                    executeOnMainThread {
                        self.view.makeToast(error.errorDescription())
                        self.getGuestKeys()
                    }
                }
            }
        }
    }
}

extension GuestKeyListViewController {
    static func instanceWithDevice(_ device: CHSesameLock) -> GuestKeyListViewController {
        let guestKeyListViewController = GuestKeyListViewController(nibName: nil, bundle: nil)
        _ = UINavigationController(rootViewController: guestKeyListViewController)
        guestKeyListViewController.device = device
        return guestKeyListViewController
    }
}

class GuestKeyListCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
