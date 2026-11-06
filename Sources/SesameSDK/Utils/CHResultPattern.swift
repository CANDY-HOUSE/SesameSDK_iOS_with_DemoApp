//
//  CHResultPattern.swift
//  SesameSDK
//
//  Created by tse on 2020/8/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

//import Foundation
public typealias CHResult<T> = (Result<CHResultState<T>, Error>) ->  ()
public class CHResultState<T> {
    public var data: T
    public init(input:T) {
        data = input
    }
}

public class CHResultStateNetworks<T>: CHResultState<T> {
    public override init(input: T) {
        super.init(input:input)
    }
}

public class CHResultStateBLE<T>: CHResultState<T> {
    public override init(input: T) {
        super.init(input:input)
    }
}

public class CHEmpty {
    public init() {}
}
