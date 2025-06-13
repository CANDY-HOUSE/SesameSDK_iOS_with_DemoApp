//
//  IRRemoteControlCell.swift
//  SesameUI
//
//  Created by eddy on 2024/1/27.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import UIKit

class IRRemoteControlCell: UICollectionViewCell {
    @IBOutlet weak var funcLabel: UILabel!
    @IBOutlet weak var stateIcon: UIImageView!
    private let bottomBorder = CALayer()
    private let rightBorder = CALayer()
    
    var longPressHandler: (() -> Void)? = nil
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = .white
        contentView.backgroundColor = .white
        bottomBorder.backgroundColor = UIColor.sesameBackgroundColor.cgColor
        layer.addSublayer(bottomBorder)
        rightBorder.backgroundColor = UIColor.sesameBackgroundColor.cgColor
        layer.addSublayer(rightBorder)
        
        contentView.isUserInteractionEnabled = true
        contentView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(onLongPressed)))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bottomBorder.frame = CGRect(x: 0,
                                    y: bounds.height - 2,
                                    width: bounds.width,
                                    height: 2)
        rightBorder.frame = CGRect(x: bounds.width - 2,
                                   y: 0,
                                   width: 2,
                                   height: bounds.height)
    }
    
    @objc func onLongPressed(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            longPressHandler?()
        }
    }
    
    
}
