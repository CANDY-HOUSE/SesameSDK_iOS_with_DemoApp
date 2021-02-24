//
//  AddFriendVC.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/2.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import SesameSDK
import UIKit

class AddFriendViewController: CHBaseViewController {
    var refreshControl:UIRefreshControl = UIRefreshControl()
    var memberList = [SSMOperator]()

    var mFriends = [CHFriend](){
        didSet {
            if self.mFriends.count == 0 {
                self.friendTable.setEmptyMessage("No Contacts".localStr)
            } else {
                self.friendTable.restore()
            }
        }
    }
    @IBOutlet weak var friendTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Contacts".localStr
        refresh(sender: "" as AnyObject)
        friendTable.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        friendTable.tableFooterView = UIView(frame: .zero)
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh".localStr)
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        self.friendTable.addSubview(refreshControl)


        memberList.forEach({
            L.d("$0.id",$0.id as Any)
        })

        let rightButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: "icons_filled_add-friends"), style: .done, target: self, action: #selector(handleRightBarButtonTapped(_:)))
              navigationItem.rightBarButtonItem = rightButtonItem
    }

    @objc func refresh(sender:AnyObject) {

        CHAccountManager.shared.myFriends(){result in
            if case .success(let result) = result {
//                L.d("🦁",result.data.first?.nickname,result.isCache)
                DispatchQueue.main.async {
                    self.mFriends = result.data.sorted { $0.nickname! < $1.nickname!}
                    self.mFriends =  self.mFriends.filter{
                        let tmp = $0.id
                        var idSame = true
                        self.memberList.forEach{
                            if($0.id == tmp){idSame = false}
                        }
                        return idSame
                    }
                    self.friendTable.reloadData()
                }
            }
            if case .failure(let error) = result{
                L.d("🦁",error)
            }
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
            }
        }
    }
}//end class
extension AddFriendViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mFriends.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FRCell", for: indexPath) as! FriendCell
        cell.nameLb.text = "\(self.mFriends[indexPath.row].nickname ?? "-")"
        cell.headImg.image = UIImage.makeLetterAvatar(withUsername: "\(self.mFriends[indexPath.row].givenname ?? "-")")
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        return cell
    }
}
extension AddFriendViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let check = UIAlertAction.addAction(title: "Add Member".localStr, style: .destructive) { (action) in
            DispatchQueue.main.async {
                ViewHelper.showLoadingInView(view: self.view)
            }
//            self.sesame?.shareKey(uuidStr: self.mFriends[indexPath.row].id!.uuidString, { (result) in
//                DispatchQueue.main.async {
//                    switch result {
//                    case .success(_):
//                        self.navigationController?.popViewController(animated: true)
//                    case .failure(let error):
//                        self.view.makeToast(error.localizedDescription)
//                    }
//                    ViewHelper.hideLoadingView(view: self.view)
//                }
//            })
        }
        UIAlertController.showAlertController(tableView.cellForRow(at: indexPath)!,title: self.mFriends[indexPath.row].nickname,style: .actionSheet, actions: [check])
    }
}
extension AddFriendViewController{
    //scan addfriend -> addmember
    @objc private func handleRightBarButtonTapped(_ sender: Any) {
        (self.tabBarController as! GeneralTabViewController).scanQR(from: "addSesame"){ (name) in
            DispatchQueue.main.async {
                ViewHelper.showLoadingInView(view: self.view)
            }
//            self.sesame?.shareKey(uuidStr: name, { result in
//                DispatchQueue.main.async {
//                    ViewHelper.hideLoadingView(view: self.view)
//                    switch result {
//                    case .success(_):
//                        self.navigationController?.popViewController(animated: true)
//                    case .failure(let error):
//                        self.view.makeToast(ErrorMessage.descriptionFromError(error: error))
//                    }
//                }
//            })
        }
    }

}
