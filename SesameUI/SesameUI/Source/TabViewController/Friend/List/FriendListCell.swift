//
//  FriendList2.swift
//  SesameUI
//
//  Created by eddy on 2023/12/6.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit

@objc(FriendListCell)
class FriendListCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

extension FriendListCell: CellConfiguration {
    func configure<T>(item: T) {
        if let friend = item as? CHUser {
            self.nameLabel.text = friend.nickname ?? friend.email
        }
    }
}
