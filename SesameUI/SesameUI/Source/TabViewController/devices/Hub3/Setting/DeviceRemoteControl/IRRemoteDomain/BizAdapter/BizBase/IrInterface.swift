//
//  IrInterface.swift
//  SesameUI
//
//  Created by wuying on 2025/3/26.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
protocol IrInterface {
    /**
     查找类型
     - Throws: 可能抛出错误
     */
    func findType(typeIndex: Int, key: Int) throws -> Data
    
    /**
     查找品牌
     - Throws: 可能抛出错误
     */
    func findBrand(brandIndex: Int, key: Int) throws -> Data
    
    /**
     搜索
     - Throws: 可能抛出错误
     */
    func search(arrayIndex: Int) throws -> [UInt8]
    
    /**
     获取学习数据
     */
    func getStudyData(data: Data, len: Int) -> Data
    
    /**
     获取品牌数组
     */
    func getBrandArray(brandIndex: Int) -> [Int]?
    
    /**
     获取类型数组
     */
    func getTypeArray(typeIndex: Int) -> [Int]?
    
    /**
     获取类型数量
     */
    func getTypeCount(typeIndex: Int) -> Int
    
    /**
     获取品牌数量
     */
    func getBrandCount(brandIndex: Int) -> Int
    
    /**
     获取表数量
     */
    func getTableCount() -> Int
}
