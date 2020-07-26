//
//  HistoryCell.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/10/14.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK


class Sesame2HistoryCell: UITableViewCell {
    var viewModel: Sesame2HistoryCellViewModel! {
        didSet {
            timeLabel.text = viewModel.timeLabelText()
            eventImage.isHidden = true
            userLabel.text = viewModel.userLabelText
            avatarImage.image = UIImage.SVGImage(named: viewModel.avatarImage)
            eventLabel.text = viewModel.historyEvent
            informationTextView.text = viewModel.information()
        }
    }
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var informationTextView: UITextView!
    
}

class Sesame2LockUnlockHistoryCell: UITableViewCell {
    var viewModel: Sesame2HistoryCellViewModel! {
        didSet {
            timeLabel.text = viewModel.timeLabelText()
            eventImage.isHidden = true
            userLabel.text = viewModel.userLabelText
            avatarImage.image = UIImage.SVGImage(named: viewModel.avatarImage)
            eventLabel.text = viewModel.historyEvent
            informationLabel.text = viewModel.information()
        }
    }
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var informationLabel: UILabel!
    
}
