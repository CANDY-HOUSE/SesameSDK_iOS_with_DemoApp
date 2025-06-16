//
//  KeyCollectionViewCell.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/11/18.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

class KeyCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var keyLevelLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var avatarBackgroundView: UIView!
    @IBOutlet weak var avatarTrailing: NSLayoutConstraint!
    @IBOutlet weak var avatarTop: NSLayoutConstraint!
    @IBOutlet weak var avatarLeading: NSLayoutConstraint!
    @IBOutlet weak var avatarBottom: NSLayoutConstraint!
    @IBOutlet weak var avatarContainerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarBackgroundView.layer.cornerRadius = 5
        avatarBackgroundView.layer.masksToBounds = true
        avatarBackgroundView.backgroundColor = .sesame2Gray
        
        avatarContainerView.backgroundColor = .white
    }

}
