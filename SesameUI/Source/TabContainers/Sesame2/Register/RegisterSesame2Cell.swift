//
//  RegisterSesame2Cell.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

protocol RegisterSesame2CellDelegate: class {
    func registerSesame2Cell(_ cell: RegisterSesame2Cell, didLongPressedAtIndexPath indexPath: IndexPath)
}

class RegisterSesame2Cell: UITableViewCell {
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var rssiImageView: UIImageView!
    @IBOutlet weak var sesame2DeviceIdLabel: UILabel!
    @IBOutlet weak var sesame2StatusLabel: UILabel! {
        didSet {
            sesame2StatusLabel.textColor = UIColor.sesame2LightGray
            sesame2StatusLabel.font = UIFont.systemFont(ofSize: 15)
        }
    }
    weak var delegate: RegisterSesame2CellDelegate?
    var indexPath: IndexPath!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        longPress.minimumPressDuration = 1.0
        addGestureRecognizer(longPress)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func longPressed() {
        delegate?.registerSesame2Cell(self, didLongPressedAtIndexPath: indexPath)
    }
    
}
