//
//  UserData.swift
//  SesameWatchKit Extension
//
//  Created by Wayne Hsiao on 2020/8/4.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import Combine

final class UserData: ObservableObject {
    static let shared = UserData()
    @Published var selectedDevice: UUID?
}
