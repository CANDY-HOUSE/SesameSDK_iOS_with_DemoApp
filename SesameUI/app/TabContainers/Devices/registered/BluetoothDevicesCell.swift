//
//  BluetoothDevicesCell.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/8/30.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK
import CoreBluetooth

class BluetoothDevicesCell: UITableViewCell {
    
    @IBAction func test(_ sender: UIButton) {
        viewModel.enterTestModeTapped()
    }

    @IBOutlet weak var batteryImage: UIImageView!
    @IBOutlet weak var powerLabel: UILabel!
    @IBOutlet weak var sesame2Circle: Sesame2Circle!
    @IBOutlet weak private var testButton: UIButton! {
        didSet {
            testButton.isHidden = true
        }
    }
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var deviceStatusLabel: UILabel!
    @IBOutlet weak var shadowStatusLabel: UILabel!
    @IBOutlet weak var lockButton: UIButton!
    
    var viewModel: BluetoothDeviceCellViewModel! {
        didSet {
            viewModel.statusUpdated = { [weak self] status in
                executeOnMainThread {
                    guard let strongSelf = self else {
                        return
                    }
                    switch status {
                    case .loading:
                        break
                    case .update:
                        strongSelf.updateSesame2Status()
                    case .finished(let result):
                        switch result {
                        case .success(_):
                            break
                        case .failure(_):
                            break
                        }
                    }
                }
                
            }
            updateInitialStatus()
        }
    }

    
    @IBAction func togleLock(_ sender: UIButton) {
        viewModel?.toggleTapped()
    }
    
    func updateInitialStatus()  {

        if let currentDegree = viewModel.currentDegree() {
            sesame2Circle.refreshUI(newPointerAngle: CGFloat(currentDegree),
                                lockColor: viewModel.lockColor)
        } else {
            sesame2Circle.refreshUI(newPointerAngle: CGFloat(0.0),
                                lockColor: viewModel.lockColor)
        }
        
        lockButton.setBackgroundImage(UIImage.CHUIImage(named: viewModel!.lockBackgroundImage()), for: .normal)
        powerLabel.text = viewModel?.powerPercentate()
        batteryImage.image = UIImage.CHUIImage(named: viewModel?.batteryImage() ?? "")
        name.text = viewModel?.name
        deviceStatusLabel.text = viewModel?.deviceStatus
        shadowStatusLabel.text = viewModel?.shadowStatus
        testButton.isHidden = viewModel?.isHideTestButton ?? true
    }
    
    func updateSesame2Status()  {

        if let currentDegree = viewModel.currentDegree() {
            sesame2Circle.refreshUI(newPointerAngle: CGFloat(currentDegree),
                                lockColor: viewModel.lockColor)
        } else {
            sesame2Circle.refreshUI(newPointerAngle: CGFloat(0.0),
                                lockColor: viewModel.lockColor)
        }
        deviceStatusLabel.text = viewModel?.deviceStatus
        shadowStatusLabel.text = viewModel?.shadowStatus
        lockButton.setBackgroundImage(UIImage.CHUIImage(named: viewModel!.lockBackgroundImage()), for: .normal)
        powerLabel.text = viewModel?.powerPercentate()
        batteryImage.image = UIImage.CHUIImage(named: viewModel?.batteryImage() ?? "")
    }
    
    deinit {
//        L.d("BluetoothDevicesCell deinit")
    }
}
