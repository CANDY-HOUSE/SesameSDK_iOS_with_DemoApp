//
//  Constant.swift
//  sesame-sdk-test-app
//
//  Created by YuHan Hsiao on 2020/5/8.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

enum Constant {
    static let storyboardName = "Main"
    static let resourceBundle = Bundle(for: BluetoothDevicesListViewController.self)
    static let storyboard = UIStoryboard(name: Constant.storyboardName,
                                         bundle: resourceBundle)
}
