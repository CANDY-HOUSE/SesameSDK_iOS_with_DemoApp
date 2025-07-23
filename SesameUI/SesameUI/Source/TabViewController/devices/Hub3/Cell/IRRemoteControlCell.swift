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
        bottomBorder.backgroundColor = UIColor.sesameRemoteBackgroundColor.cgColor
        layer.addSublayer(bottomBorder)
        rightBorder.backgroundColor = UIColor.sesameRemoteBackgroundColor.cgColor
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
    
    func configureBordersForPosition(indexPath: IndexPath, totalItems: Int, numberOfColumns: Int = 3) {
        let currentRow = indexPath.item / numberOfColumns
        let currentColumn = indexPath.item % numberOfColumns
        let totalRows = (totalItems + numberOfColumns - 1) / numberOfColumns
        let showRightBorder = (currentColumn != numberOfColumns - 1)
        let showBottomBorder = currentRow != totalRows - 1
        
        bottomBorder.isHidden = !showBottomBorder
        rightBorder.isHidden = !showRightBorder
    }
    
}
