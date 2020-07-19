//
//  AddFriendVC.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/2.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import SesameSDK
import UIKit

//public final class AddFriendViewController: CHBaseViewController {
//    var viewModel: AddFriendViewModel!
//    var refreshControl:UIRefreshControl = UIRefreshControl()
//    
//    @IBOutlet weak var friendTable: UITableView!
//
//    public override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        assert(viewModel != nil, "AddFriendViewModel should not be nil")
//        
//        viewModel.statusUpdated = { [weak self] status in
//            guard let strongSelf = self else {
//                return
//            }
//            switch status {
//            case .loading:
//                break
//            case .received:
//                strongSelf.refreshUI()
//            case .finished(let result):
//                switch result {
//                case .success(_):
//                    strongSelf.refreshUI()
//                case .failure(_):
//                    strongSelf.refreshUI()
//                }
//            }
//        }
//        
//        refresh(sender: "" as AnyObject)
//        friendTable.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
//        friendTable.tableFooterView = UIView(frame: .zero)
//        refreshControl.attributedTitle = NSAttributedString(string: viewModel.refreshControlTitle)
//        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
//        friendTable.addSubview(refreshControl)
//
//        let rightButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: viewModel.rightButtonItemImage),
//                                              style: .done,
//                                              target: self,
//                                              action: #selector(handleRightBarButtonTapped(_:)))
//        navigationItem.rightBarButtonItem = rightButtonItem
//    }
//    
//    public override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        title = viewModel.title
//    }
//
//    @objc func refresh(sender:AnyObject) {
//        viewModel.refresh()
//    }
//    
//    func refreshUI() {
//        if viewModel.numberOfRows == 0 {
//            friendTable.setEmptyMessage(viewModel.emptyMessage)
//        } else {
//            friendTable.restore()
//        }
//    }
//}
//
//extension AddFriendViewController: UITableViewDataSource {
//
//    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return viewModel.numberOfRows
//    }
//
//    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "FRCell", for: indexPath) as! FriendCell
//        let cellModel = viewModel.friendCellModelForRow(indexPath.row)
//        cell.nameLb.text = cellModel.name()
//        cell.headImg.image = UIImage.makeLetterAvatar(withUsername: cellModel.headImage())
//        cell.selectionStyle = UITableViewCell.SelectionStyle.none
//        return cell
//    }
//}
//
//extension AddFriendViewController: UITableViewDelegate {
//    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let check = UIAlertAction.addAction(title: self.viewModel.addFriendActionTitle,
//                                            style: .destructive) { (action) in
//            self.viewModel.addFriendActionForRow(indexPath.row)
//        }
//        UIAlertController.showAlertController(tableView.cellForRow(at: indexPath)!,
//                                              title: self.viewModel.addFriendTitleForRow(indexPath.row),
//                                              style: .actionSheet,
//                                              actions: [check])
//    }
//}
//
//extension AddFriendViewController{
//    //scan addfriend -> addmember
//    @objc private func handleRightBarButtonTapped(_ sender: Any) {
//        viewModel.rightBarButtonTapped()
//    }
//}
