//
//  WifiModule2ListCell.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/8/19.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

class WifiModule2ListCell: UITableViewCell {
    
    @IBOutlet var batteryImage: UIImageView!
    @IBOutlet var name: UILabel!
    @IBOutlet var ownerNameLabel: UILabel!
    @IBOutlet var powerLabel: UILabel!
    @IBOutlet var testButton: UIButton!
    
    var viewModel: WifiModule2ListCellModel! {
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
                        strongSelf.updateUI()
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

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateUI() {
        name.text = viewModel.name()
        ownerNameLabel.text = viewModel.ownerName()
    }

    @IBAction func test(_ sender: UIButton) {
        
    }
}
