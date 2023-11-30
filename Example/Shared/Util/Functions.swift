//
//  Functions.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation

public func executeOnMainThread(_ execution: @escaping ()->Void) {
    if Thread.isMainThread {
        execution()
    } else {
        DispatchQueue.main.async {
            execution()
        }
    }
}

public func angle2degree(angle: Int16) -> Float {

    var degree = Float(angle % 1024)
    degree = degree * 360 / 1024
    if degree > 0 {
        degree = 360 - degree
    } else {
        degree = abs(degree)
    }
    return degree
}
public func reverseDegree(angle: Int16) -> Float {

    var degree = Float(angle % 1024)
    if degree > 0 {
        degree = 360 - degree
    } else {
        degree = abs(degree)
    }
    return degree
}

