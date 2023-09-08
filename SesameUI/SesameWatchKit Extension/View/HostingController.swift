//
//  HostingController.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/5/30.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import SwiftUI

class HostingController: WKHostingController<ContentView> {
    override var body: ContentView {
        .init(viewModel: .init(sesameData: SesameData.shared))
    }
}
