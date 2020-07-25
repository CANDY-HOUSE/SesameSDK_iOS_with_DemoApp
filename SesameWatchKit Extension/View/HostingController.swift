//
//  HostingController.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/5/30.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import WatchKit
import Foundation
import SwiftUI

class HostingController: WKHostingController<ContentView<DeviceModelProvider>> {
    override var body: ContentView<DeviceModelProvider> {
        return ContentView(viewModel: .init())
    }
}

//struct HostingController_Previews: PreviewProvider {
//    static var previews: some View {
//        return ContentView(viewModel: .init(deviceProvider: MockDeviceProvider()))
//    }
//}
