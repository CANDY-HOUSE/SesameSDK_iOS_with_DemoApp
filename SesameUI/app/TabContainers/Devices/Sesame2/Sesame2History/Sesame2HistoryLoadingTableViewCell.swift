//
//  Sesame2HistoryLoadingTableViewCell.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/8/23.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

class Sesame2HistoryLoadingTableViewCell: UITableViewCell {
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var informationTextView: UITextView!
    
    var viewModel: Sesame2HistoryCellViewModel! {
        didSet {
            timeLabel.text = viewModel.timeLabelText()
            userLabel.text = viewModel.userLabelText
            avatarImage.image = UIImage.SVGImage(named: viewModel.avatarImage)
            eventLabel.text = viewModel.historyEvent
            informationTextView.text = viewModel.information()
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
    
    override func prepareForReuse() {
        loadingIndicator.startAnimating()
    }
    
    static func instanceFromNib() -> Sesame2HistoryLoadingTableViewCell {
        return UINib(nibName: "Sesame2HistoryLoadingTableViewCell", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! Sesame2HistoryLoadingTableViewCell
    }
    
}
