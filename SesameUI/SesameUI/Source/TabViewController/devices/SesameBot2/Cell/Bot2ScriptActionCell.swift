//
//  Bot2ScriptActionCell.swift
//  SesameUI
//
//  Created by eddy on 2023/12/15.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

@objc(Bot2ScriptActionCell)
class Bot2ScriptActionCell: UITableViewCell {

    @IBOutlet weak var actionBtn: UIButton!
    @IBOutlet weak var timeLab: UILabel!
    var action: Bot2Action!
    var onActionChange: ((Bot2Action) -> Void)?
    var onDeleteTapped: ((Bot2Action) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        actionBtn.setTitle("", for: .normal)
        actionBtn.titleEdgeInsets = UIEdgeInsets.zero
        actionBtn.contentHorizontalAlignment = .center
        actionBtn.contentVerticalAlignment = .center
        let deleteBtn =  UIImageView(image: UIImage.SVGImage(named: "delete", fillColor: .gray))
        deleteBtn.isUserInteractionEnabled = true
        deleteBtn.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onDeleteButtonPressed)))
        accessoryView = deleteBtn
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}

extension Bot2ScriptActionCell: CellConfiguration {
    func configure<T>(item: T) {
        guard let action = item as? Bot2Action else { return }
        self.action = action
        actionBtn.setImage(UIImage.SVGImage(named: action.actionIcon, fillColor: .sesame2LightGray), for: .normal)
        actionBtn.addTarget(self, action: #selector(onActionButtonPressed), for: .touchUpInside)
        timeLab?.text = action.time.displayedActionTime
    }
    
    @objc func onActionButtonPressed() {
        self.action.action = self.action.actionType
        onActionChange?(self.action)
    }
    
    @objc func onDeleteButtonPressed() {
        onDeleteTapped?(self.action)
    }
}
