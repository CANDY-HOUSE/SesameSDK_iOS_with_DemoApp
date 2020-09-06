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
    func dfuTapped(cell: UITableViewCell)
}

class RegisterCell: UITableViewCell {

    @IBOutlet weak var modelLb: UILabel!
    @IBOutlet weak var ssi: UILabel!
    @IBOutlet weak var bluetoothImg: UIImageView!
    @IBOutlet weak var statusLabel: UILabel! {
        didSet {
            statusLabel.textColor = UIColor.sesame2LightGray
            statusLabel.font = UIFont.systemFont(ofSize: 15)
        }
    }
    weak var delegate: RegisterCellDelegate?
    var longPress: UILongPressGestureRecognizer?
    
    var viewModel: RegisterCellModel! {
        didSet {
            ssi.text = viewModel.ssiText()
            bluetoothImg.image = UIImage.SVGImage(named: viewModel.bluetoothImage(),
                                                  fillColor: .sesame2Green)
            modelLb.text = viewModel.modelLabelText()
            statusLabel.text = viewModel.currentSesame2Status()
            
            if gestureRecognizers == nil || longPress == nil {
                self.longPress = UILongPressGestureRecognizer(target: self, action: #selector(RegisterCell.dfuTapped(_:)))
                longPress!.minimumPressDuration = 1.0
                addGestureRecognizer(longPress!)
            }
        }
    }
    
    @objc
    @IBAction func dfuTapped(_ sender: Any) {
        delegate?.dfuTapped(cell: self)
    }
    
    deinit {
        if let longPress = longPress {
            removeGestureRecognizer(longPress)
        }
    }
}
