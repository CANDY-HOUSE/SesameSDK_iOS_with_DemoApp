//
//  Response.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2021/08/11.
//  Copyright © 2021 CandyHouse. All rights reserved.
//

import Foundation

typealias CHResult<T> = (Result<CHResultState<T>, Error>) ->  ()

class CHResultState<T> {
    var data: T
    init(input:T) {
        data = input
    }
}

class CHResultStateCache<T>: CHResultState<T> {
    override init(input: T) {
        super.init(input:input)
    }
}

class CHResultStateNetworks<T>: CHResultState<T> {
    override init(input: T) {
        super.init(input:input)
    }
}
class CHResultStateBLE<T>: CHResultState<T> {
    override init(input: T) {
        super.init(input:input)
    }
}
