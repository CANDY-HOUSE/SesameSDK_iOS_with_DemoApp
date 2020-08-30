//
//  WifiSelectionTableViewCell.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

class WifiSelectionTableViewCell: UITableViewCell {
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var ssidLabel: UILabel!
    
    var viewModel: WifiSelectionTableViewCellModel! {
        didSet {
            rssiLabel?.text = viewModel.distanceInCentermiter()
            ssidLabel?.text = viewModel.ssid
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
