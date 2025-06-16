//
//  UITableView+.swift
//  SesameUI
//
//  Created by eddy on 2024/4/11.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

extension UITableView {
    func safelyScrollToRow(at indexPath: IndexPath, position scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        if indexPath.section >= 0, indexPath.section < numberOfSections, indexPath.row >= 0, indexPath.row < numberOfRows(inSection: indexPath.section) {
            scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
        } else {
            L.d("Attempted to scroll to an invalid IndexPath: \(indexPath)")
        }
    }
}
