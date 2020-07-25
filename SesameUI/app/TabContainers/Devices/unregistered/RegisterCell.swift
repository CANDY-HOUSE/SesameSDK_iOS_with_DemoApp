//
//  RegisterCell.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/18.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK
import CoreBluetooth

protocol RegisterCellDelegate: class {
    func dfuForCell(_ cell: UITableViewCell)
}

class RegisterCell: UITableViewCell {

    weak var delegate: RegisterCellDelegate?
    @IBOutlet weak var modelLb: UILabel!
    @IBOutlet weak var ssi: UILabel!
    @IBOutlet weak var bluetoothImg: UIImageView!
    @IBOutlet weak var dfuButton: UIButton! {
        didSet {
            dfuButton.isHidden = true
            dfuButton.addTarget(delegate, action: #selector(RegisterCell.dfuTapped), for: .touchUpInside)
        }
    }
    @IBOutlet weak var firmwareVersionLabel: UILabel! {
        didSet {
            firmwareVersionLabel.isHidden = true
        }
    }
    @IBOutlet weak var statusLabel: UILabel! {
        didSet {
            statusLabel.textColor = UIColor.sesame2LightGray
            statusLabel.font = UIFont.systemFont(ofSize: 15)
        }
    }
    
    var viewModel: RegisterCellModel! {
        didSet {
            ssi.text = viewModel.ssiText()
            bluetoothImg.image = UIImage.SVGImage(named: viewModel.bluetoothImage(),
                                                  fillColor: .sesame2Green)
            modelLb.text = viewModel.modelLabelText()
            statusLabel.text = viewModel.currentStatus()
        }
    }
    
    @objc func dfuTapped() {
        delegate?.dfuForCell(self)
    }
}
