//
//  Hub3IRCodeViewCell.swift
//  SesameUI
//
//  Created by eddy on 2024/1/8.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

@objc(Hub3IREmitCell)
class Hub3IREmitCell: UITableViewCell {
    @IBOutlet weak var deviceNameLab: UILabel!
    @IBOutlet weak var sesame2Circle: Sesame2Circle!
    @IBOutlet weak var sesame2CircleButton: UIButton!
    private var dataSource: CellSubItemDiscriptor!
    
    var clickHandler: (() -> Void)? = nil
    var device: CHDevice! {
        didSet {
            device.multicastDelegate.addDelegate(self)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        prepareHapticFeedback()
    }

    @IBAction func sesame2circleBtnTaped(_ sender: Any) {
        clickHandler?()
        triggerHapticFeedback()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        prepareHapticFeedback()
    }
}

extension Hub3IREmitCell: CHDeviceStatusAndKeysDelegate {
    func onSesame2KeysChanged(device: CHWifiModule2, sesame2keys: [String : String]) { }
    
    func onBleDeviceStatusChanged(device: CHDevice, status: CHDeviceStatus, shadowStatus: CHDeviceStatus?) {
        executeOnMainThread { [self] in
            if let icon = dataSource.iconWithDevice(device) {
                self.sesame2CircleButton.setBackgroundImage(UIImage(named: icon), for: .normal)
            }
        }
    }
}

extension Hub3IREmitCell: CellConfiguration {
    func configure<T>(item: T) {
        guard let subDes = item as? CellSubItemDiscriptor else {
            return
        }
        dataSource = subDes
        deviceNameLab.text = subDes.title
        let icon = subDes.iconWithDevice(device)
        sesame2Circle.isHidden = icon?.isEmpty == nil
        if !sesame2Circle.isHidden {
            sesame2CircleButton.setBackgroundImage(UIImage(named: icon!), for: .normal)
        }
    }
}
