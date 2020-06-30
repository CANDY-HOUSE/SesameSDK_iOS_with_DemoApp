//
//  FriendsViewController.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/10/9.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import UIKit
import SesameSDK
import AWSMobileClient

public protocol FriendDelegate: class {
    func  refreshFriendPage()
}

class FriendsViewController: CHBaseViewController {
    var viewModel: FriendsViewModel!
    
    private var menuFloatView: PopUpMenuControl?
    private func showMoreMenu() {
        if menuFloatView == nil {
            let y = Constants.statusBarHeight + 44
            let frame = CGRect(x: 0, y: y, width: view.bounds.width, height: view.bounds.height - y)
            menuFloatView = PopUpMenuControl(frame: frame)
            menuFloatView?.delegate = self
        }
        menuFloatView?.show(in: self.view)
    }
    
    private func hideMoreMenu(animated: Bool = true) {
        menuFloatView?.hide(animated: animated)
    }
    
    @IBOutlet weak var friendsTables: UITableView!
    var refreshControl:UIRefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(viewModel != nil, "FriendsViewModel should not be nil")
        
        viewModel.statusUpdated = { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            switch status {
            case .loading:
                break
            case .received:
                break
            case .finished(let result):
                switch result {
                case .success(_):
                    
                    if strongSelf.viewModel.numberOfRows() == 0 {
                        // TODO: Internationalization
                        strongSelf.friendsTables.setEmptyMessage(strongSelf.viewModel.emptyMessage)
                    } else {
                        strongSelf.friendsTables.restore()
                    }
                case .failure(let error):
                    strongSelf.view.makeToast(error.localizedDescription)
                }
            }
        }
        
        let rightButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: viewModel.rightbuttonItemImage()),
                                              style: .done,
                                              target: self,
                                              action: #selector(handleRightBarButtonTapped(_:)))
           navigationItem.rightBarButtonItem = rightButtonItem

        
        if #available(iOS 13.0, *) {
                  self.navigationController?.navigationBar.standardAppearance.shadowColor = .clear
              } else {
                  // Fallback on earlier versions
              }
        
        viewModel.refresh()
        
        friendsTables.tableFooterView = UIView(frame: .zero)
        refreshControl.attributedTitle = NSAttributedString(string: viewModel.pullToRefreshTitle)
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.friendsTables.addSubview(refreshControl)
        
    }
    
    @objc func refresh(sender:AnyObject) {
        viewModel.refresh()
    }
}

extension FriendsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FRCell", for: indexPath) as! FriendCell
        let cellModel = viewModel.friendCellModelForRow(indexPath.row)
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.nameLb.text = cellModel.name()
        cell.headImg.image = UIImage.makeLetterAvatar(withUsername: cellModel.headImage())
        return cell
    }
}

extension FriendsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let check = UIAlertAction.addAction(title: viewModel.actonTitle,
                                            style: .destructive) { (action) in

                                                self.viewModel.tableViewDidSelectRowAt(indexPath.row)
        }
        UIAlertController.showAlertController(tableView.cellForRow(at: indexPath)!,
                                              title: viewModel.titleForSelectedRow(indexPath.row),
                                              style: .actionSheet,
                                              actions: [check])

    }
    
}

extension FriendsViewController: PopUpMenuDelegate {
    @objc private func handleRightBarButtonTapped(_ sender: Any) {
        if self.menuFloatView?.superview != nil {
            hideMoreMenu()
        } else {
            showMoreMenu()
        }
    }
    
    func popUpMenu(_ menu: PopUpMenu, didTap item: PopUpMenuItem) {
        viewModel.popUpMenuTappedOnItem(item)
        hideMoreMenu(animated: false)
    }
}
