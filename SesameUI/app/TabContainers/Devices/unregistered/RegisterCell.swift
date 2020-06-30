//
//  RegisterCell.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/18.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK
import CoreBluetooth

class RegisterCell: UITableViewCell {

    @IBOutlet weak var modelLb: UILabel!
    @IBOutlet weak var ssi: UILabel!
    @IBOutlet weak var bluetoothImg: UIImageView!
    
    var viewModel: RegisterCellModel! {
        didSet {
            ssi.text = viewModel.ssiText()
            bluetoothImg.image = UIImage.SVGImage(named: viewModel.bluetoothImage(),
                                                  fillColor: .sesameGreen)
            modelLb.text = viewModel.modelLabelText()
        }
    }
}
