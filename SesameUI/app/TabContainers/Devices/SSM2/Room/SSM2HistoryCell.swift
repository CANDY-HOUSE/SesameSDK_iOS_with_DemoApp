//
//  HistoryCell.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/10/14.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK


class SSM2HistoryCell: UITableViewCell {
    var viewModel: SSM2HistoryCellViewModel! {
        didSet {
            timeLabel.text = viewModel.timeLabelText()
            eventImage.isHidden = true
            userLabel.text = viewModel.userLabelText
            avatarImage.image = UIImage.SVGImage(named: viewModel.avatarImage)
        }
    }
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
}
