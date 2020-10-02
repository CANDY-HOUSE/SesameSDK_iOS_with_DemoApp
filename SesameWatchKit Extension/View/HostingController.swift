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

class HostingController: WKHostingController<ContentView> {
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        #if DEBUG
        guard let path = Bundle.main.path(forResource: "git", ofType: "plist"),
            let gitPlistContent = NSDictionary(contentsOfFile: path) as? [String : Any],
            let commit = gitPlistContent["GitCommit"] as? String else {
                return
        }
        setTitle(commit)
        #endif
    }
//    override var body: ContentView<DeviceModelProvider> {
//        return ContentView(viewModel: .init())
//    }
    override var body: ContentView {
        return ContentView()
    }
}

//struct HostingController_Previews: PreviewProvider {
//    static var previews: some View {
//        Group {
//           ContentView(viewModel: .init(deviceProvider: MockDeviceProvider()))
//              .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 5 - 40mm"))
//              .previewDisplayName("Apple Watch Series 5 - 40mm")
//
//           ContentView(viewModel: .init(deviceProvider: MockDeviceProvider()))
//              .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 5 - 44mm"))
//              .previewDisplayName("Apple Watch Series 5 - 44mm")
//        }
//    }
//}
