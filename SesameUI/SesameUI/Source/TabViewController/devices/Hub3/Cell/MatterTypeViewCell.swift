//
//  MatterTypeViewCell.swift
//  SesameUI
//
//  Created by eddy on 2024/1/5.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import UIKit

@objc(MatterTypeViewCell)
class MatterTypeViewCell: UITableViewCell {

    @IBOutlet weak var iconImgView: UIImageView!
    @IBOutlet weak var nameLab: UILabel!
    @IBOutlet weak var matterSwitch: UISwitch!
    
    var onActionChange: ((MatterTypeItem) -> Void)?

    private var model: MatterTypeItem!

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

extension MatterTypeViewCell: CellConfiguration {
    func configure<T>(item: T) {
        guard let model = item as? MatterTypeItem else { return }
        self.model = model
        iconImgView.image = UIImage.SVGImage(named: model.icon)
        nameLab.text = model.name
        matterSwitch.isOn = model.isOn
        matterSwitch.addTarget(self, action: #selector(onActionButtonPressed(sender:)), for: .valueChanged)
    }
    
    @objc func onActionButtonPressed(sender: UISwitch) {
        sender.setOn(sender.isOn, animated: true)
        self.model.isOn = sender.isOn
        self.onActionChange?(self.model)
    }
}
