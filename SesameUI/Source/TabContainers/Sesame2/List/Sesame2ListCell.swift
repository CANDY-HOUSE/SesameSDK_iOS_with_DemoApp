//
//  Sesame2ListCell.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

protocol Sesame2ListCellDelegate: class {
    func sesame2CircleTapped(_ cell: Sesame2ListCell)
    func debugModeTapped(_ cell: Sesame2ListCell)
}

class Sesame2ListCell: UITableViewCell {

    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var sesame2StatusLabel: UILabel!
    @IBOutlet weak var sesame2ShadowStatusLabel: UILabel!
    @IBOutlet weak var sesame2AngleLabel: UILabel!
    
    @IBOutlet weak var sesame2Circle: Sesame2Circle!
    @IBOutlet weak var sesame2CircleButton: UIButton!
    @IBOutlet weak var batteryPercentageLabel: UILabel!
    @IBOutlet weak var batteryImageView: UIImageView!
    @IBOutlet weak var debugModeButton: UIButton!

    weak var delegate: Sesame2ListCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateSesameCircle(lockAngle: CGFloat, lockColor: UIColor) {
        sesame2Circle.refreshUI(newPointerAngle: lockAngle,
                                lockColor: lockColor)
    }
    
    @IBAction func sesame2CircleTapped(_ sender: Any) {
        delegate?.sesame2CircleTapped(self)
    }
    
    @IBAction func debugModeTapped(_ sender: Any) {
        delegate?.debugModeTapped(self)
    }
}
