//
//  DeleteFriendVC.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/12.
//  Copyright © 2019 Cerberus. All rights reserved.
//


import SesameSDK
import UIKit

//class DeleteFriendViewController: CHBaseViewController {
//    var viewModel: DeleteFriendViewModel!
//    
//    @IBOutlet weak var friendTable: UITableView!
//    var refreshControl:UIRefreshControl = UIRefreshControl()
//    var memberList = [Sesame2Operator]()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        assert(viewModel != nil, "DeleteFriendViewModel should not be nil")
//        friendTable.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
//        friendTable.tableFooterView = UIView(frame: .zero)
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        title = viewModel.title
//    }
//}
//
//extension DeleteFriendViewController: UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return viewModel.numberOfRows
//    }
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "FRCell", for: indexPath) as! FriendCell
//        let cellViewModel = viewModel.friendCellViewModelForRow(indexPath.row)
//        cell.nameLb.text = cellViewModel.name()
//        cell.headImg.image = UIImage.makeLetterAvatar(withUsername: cellViewModel.headImage())
//        cell.selectionStyle = UITableViewCell.SelectionStyle.none
//        return cell
//    }
//}
//
//extension DeleteFriendViewController: UITableViewDelegate {
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let check = UIAlertAction.addAction(title: viewModel.deleteFriendActionTitle,
//                                            style: .destructive) { (action) in
//                                                self.viewModel.deleteFriendActionForRow(indexPath.row)
//        }
//        UIAlertController.showAlertController(tableView.cellForRow(at: indexPath)!,title: self.memberList[indexPath.row].name,style: .actionSheet, actions: [check])
//    }
//}
