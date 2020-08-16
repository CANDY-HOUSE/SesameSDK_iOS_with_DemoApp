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
//    override func awake(withContext context: Any?) {
//        setTitle("Sesame")
//    }
    override var body: ContentView<DeviceModelProvider> {
        return ContentView(viewModel: .init())
    }
}

struct HostingController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
           ContentView(viewModel: .init(deviceProvider: MockDeviceProvider()))
              .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 5 - 40mm"))
              .previewDisplayName("Apple Watch Series 5 - 40mm")

           ContentView(viewModel: .init(deviceProvider: MockDeviceProvider()))
              .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 5 - 44mm"))
              .previewDisplayName("Apple Watch Series 5 - 44mm")
        }
    }
}
