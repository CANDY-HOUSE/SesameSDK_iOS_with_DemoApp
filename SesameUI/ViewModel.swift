//
//  ViewModel.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

public enum ViewStatus {
    case loading
    case update(Any?)
    case finished(Result<Any, Error>)
}

public typealias ViewStatusHandler = (ViewStatus) -> Void

public protocol ViewModel: class {
    var statusUpdated: ViewStatusHandler? { get set }
}
