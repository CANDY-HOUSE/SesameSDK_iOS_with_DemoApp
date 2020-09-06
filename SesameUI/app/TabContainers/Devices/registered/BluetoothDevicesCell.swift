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
                        strongSelf.refreshUI()
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
            updateInitialUI()
        }
    }

    
    @IBAction func togleLock(_ sender: UIButton) {
        viewModel?.sesame2LockTapped()
    }
    
    func updateInitialUI()  {

        if let currentDegree = viewModel.currentDegree() {
            sesame2Circle.refreshUI(newPointerAngle: CGFloat(currentDegree),
                                lockColor: viewModel.lockColor)
        } else {
            sesame2Circle.refreshUI(newPointerAngle: CGFloat(0.0),
                                lockColor: viewModel.lockColor)
        }
        
        lockButton.setBackgroundImage(UIImage.CHUIImage(named: viewModel!.sesame2LockImage()), for: .normal)
        powerLabel.text = viewModel?.powerPercentate()
        batteryImage.image = UIImage.CHUIImage(named: viewModel?.batteryImage() ?? "")
        name.text = viewModel?.sesame2Name
        deviceStatusLabel.text = viewModel?.sesame2DeviceStatus
        shadowStatusLabel.text = viewModel?.sesame2ShadowStatus
        testButton.isHidden = viewModel?.isHideTestButton ?? true
    }
    
    func refreshUI()  {

        if let currentDegree = viewModel.currentDegree() {
            sesame2Circle.refreshUI(newPointerAngle: CGFloat(currentDegree),
                                lockColor: viewModel.lockColor)
        } else {
            sesame2Circle.refreshUI(newPointerAngle: CGFloat(0.0),
                                lockColor: viewModel.lockColor)
        }
        deviceStatusLabel.text = viewModel?.sesame2DeviceStatus
        shadowStatusLabel.text = viewModel?.sesame2ShadowStatus
        lockButton.setBackgroundImage(UIImage.CHUIImage(named: viewModel!.sesame2LockImage()), for: .normal)
        powerLabel.text = viewModel?.powerPercentate()
        batteryImage.image = UIImage.CHUIImage(named: viewModel?.batteryImage() ?? "")
    }
    
    deinit {
//        L.d("BluetoothDevicesCell deinit")
    }
}
