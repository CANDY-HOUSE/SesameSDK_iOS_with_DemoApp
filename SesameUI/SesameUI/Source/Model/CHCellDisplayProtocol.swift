//
//  CHCellDisplayProtocol.swift
//  SesameUI
//  table cell 配置
//  Created by eddy on 2023/12/5.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

public protocol CellConfiguration {
//    cell cls，理論上一種數據結構對應一個樣式
    var cellCls: AnyClass! { get }
//    cell 配置
    func configure<T>(item: T)
}

extension CellConfiguration {
    var cellCls: AnyClass! { return UITableViewCell.self }
    func configure<T>(item: T) {}
}
