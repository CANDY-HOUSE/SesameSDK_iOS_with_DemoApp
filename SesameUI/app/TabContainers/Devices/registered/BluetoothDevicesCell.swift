//
//  BluetoothDevicesCell.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/8/30.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK
import CoreBluetooth

class BluetoothDevicesCell: UITableViewCell {
    
    @IBAction func test(_ sender: UIButton) {
        // TODO: Fix test view
//        vc?.performSegue(withIdentifier:  "toDeviceDetail", sender: ssm)
        viewModel.enterTestModeTapped()
    }
//    public var vc:UIViewController?


    @IBOutlet weak var batteryImage: UIImageView!
    @IBOutlet weak var powerLabel: UILabel!
    @IBOutlet weak var ssmCircle: SesameCircle!
    @IBOutlet weak private var testButton: UIButton! {
        didSet {
            testButton.isHidden = true
        }
    }
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var ownerNameLabel: UILabel!
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
                    case .received:
                        strongSelf.updateSSMStatus()
//                        strongSelf.updateUI()
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
            updateUI()
        }
    }

    
    @IBAction func togleLock(_ sender: UIButton) {
        viewModel?.toggleTapped()
    }
    
    func updateUI()  {

        if let currentDegree = viewModel.currentDegree() {
            ssmCircle.refreshUI(newPointerAngle: CGFloat(currentDegree),
                                lockColor: viewModel.lockColor)
        } else {
            ssmCircle.refreshUI(newPointerAngle: CGFloat(0.0),
                                lockColor: viewModel.lockColor)
        }
        
        lockButton.setBackgroundImage(UIImage.CHUIImage(named: viewModel!.lockBackgroundImage()), for: .normal)
        powerLabel.text = viewModel?.powerPercentate()
        batteryImage.image = UIImage.CHUIImage(named: viewModel?.batteryImage() ?? "")
        name.text = viewModel?.name
        ownerNameLabel.text = viewModel?.ownerNameLabel
        ownerNameLabel.isHidden = viewModel?.isHideOwnerNameLabel ?? true
        testButton.isHidden = viewModel?.isHideTestButton ?? true
    }
    func updateSSMStatus()  {

        if let currentDegree = viewModel.currentDegree() {
            ssmCircle.refreshUI(newPointerAngle: CGFloat(currentDegree),
                                lockColor: viewModel.lockColor)
        } else {
            ssmCircle.refreshUI(newPointerAngle: CGFloat(0.0),
                                lockColor: viewModel.lockColor)
        }

        lockButton.setBackgroundImage(UIImage.CHUIImage(named: viewModel!.lockBackgroundImage()), for: .normal)
        powerLabel.text = viewModel?.powerPercentate()
        batteryImage.image = UIImage.CHUIImage(named: viewModel?.batteryImage() ?? "")
    }
    
//    func viewWillAppear() {
//        viewModel.viewWillAppear()
//        updateUI()
//    }
    
    deinit {
        L.d("BluetoothDevicesCell deinit")
    }
}
