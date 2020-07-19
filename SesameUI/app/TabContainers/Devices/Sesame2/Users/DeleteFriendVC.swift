//
//  DeleteFriendVC.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/12.
//  Copyright © 2019 Cerberus. All rights reserved.
//


import SesameSDK
import UIKit

class DeleteFriendViewController: CHBaseViewController {
    @IBOutlet weak var friendTable: UITableView!
    var refreshControl:UIRefreshControl = UIRefreshControl()
    var memberList = [SSMOperator]()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Members".localStr
        friendTable.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        friendTable.tableFooterView = UIView(frame: .zero)
    }
}

extension DeleteFriendViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.memberList.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FRCell", for: indexPath) as! FriendCell
        cell.nameLb.text = "\(self.memberList[indexPath.row].name ?? "?")"
        cell.headImg.image = UIImage.makeLetterAvatar(withUsername: "\(self.memberList[indexPath.row].firstname ?? "?")")
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        return cell
    }
}

extension DeleteFriendViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let check = UIAlertAction.addAction(title: "Delete the Member".localStr, style: .destructive) { (action) in
            ViewHelper.showLoadingInView(view: self.view)
            let member = self.memberList[indexPath.row]
//            self.sesame!.revokeKey(member.id) { (result) in
//                DispatchQueue.main.async {
//                    ViewHelper.hideLoadingView(view: self.view)
//                }
//                switch result {
//                case .success(_):
//                    self.sesame?.getDeviceMembers() { result in
//                        DispatchQueue.main.async {
//                            switch result {
//                            case .success(let users):
//                                self.memberList = users.data
//                                self.friendTable.reloadData()
//                            case .failure(let error):
//                                L.d(ErrorMessage.descriptionFromError(error: error))
//                                self.navigationController?.popToRootViewController(animated: true)
//                            }
//                        }
//                    }
//                case .failure(let error):
//                    L.d(ErrorMessage.descriptionFromError(error: error))
//                }
//            }
        }
        UIAlertController.showAlertController(tableView.cellForRow(at: indexPath)!,title: self.memberList[indexPath.row].name,style: .actionSheet, actions: [check])
    }
}
