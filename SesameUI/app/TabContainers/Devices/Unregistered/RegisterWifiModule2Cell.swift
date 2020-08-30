//
//  RegisterWifiModule2Cell.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

protocol RegisterWifiModule2CellDelegate: class {
    func dfuTapped(cell: UITableViewCell)
}

class RegisterWifiModule2Cell: UITableViewCell {
    @IBOutlet weak var ssiLabel: UILabel!
    @IBOutlet weak var bluetoothImage: UIImageView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var deviceStatusLabel: UILabel! {
        didSet {
            deviceStatusLabel.textColor = UIColor.sesame2LightGray
            deviceStatusLabel.font = UIFont.systemFont(ofSize: 15)
        }
    }
    @IBOutlet weak var dfuButton: UIButton! {
        didSet {
            dfuButton.isHidden = true
        }
    }
    weak var delegate: RegisterWifiModule2CellDelegate?
    
    var viewModel: RegisterWifiModule2CellModel! {
        didSet {
            ssiLabel.text = viewModel.rssi()
            bluetoothImage.image = UIImage.SVGImage(named: viewModel.bluetoothImage(),
                                                  fillColor: .sesame2Green)
            deviceNameLabel.text = viewModel.deviceName()
            deviceStatusLabel.text = viewModel.deviceStatus()
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
    
    @IBAction func dfuTapped(_ sender: Any) {
        delegate?.dfuTapped(cell: self)
    }
}
