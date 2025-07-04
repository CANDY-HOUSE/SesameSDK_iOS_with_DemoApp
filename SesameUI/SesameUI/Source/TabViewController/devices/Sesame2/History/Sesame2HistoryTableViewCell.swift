//
//  CHSesame2HistoryTableViewCell.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/9/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

class Sesame2HistoryTableViewCell: UITableViewCell {
    @IBOutlet weak var loadingContainerView: UIView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var historyTypeImageView: UIImageView!
    @IBOutlet weak var historyTagLabel: UILabel!
    @IBOutlet weak var loadingContainerHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        
        hideLoadingIndicator()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func showLoadingIndicator() {
        loadingIndicator.startAnimating()
        loadingContainerHeightConstraint.constant = 60
    }
    
    func hideLoadingIndicator() {
        loadingIndicator.stopAnimating()
        loadingContainerHeightConstraint.constant = 0
    }

}
