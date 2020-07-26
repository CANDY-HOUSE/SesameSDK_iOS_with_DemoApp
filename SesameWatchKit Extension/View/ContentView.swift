//
//  ContentView.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/5/30.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import SwiftUI

struct ContentView<ContentProvider: Provider>: View {
    @ObservedObject var viewModel: ContentViewModel<ContentProvider>

    var body: some View {
        GeometryReader { geometry in
            if self.viewModel.isShowContent {
                self.content(geometry: geometry)
            } else {
                VStack {
                    Spacer()
                    Text(self.viewModel.displayText)
                        .foregroundColor(Color(self.viewModel.displayColor))
                        .font(.headline)
                    Spacer()
                }
            }
        }
    }
    
    func content(geometry: GeometryProxy) -> some View {
        return ForEach(0..<1) { _ in
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .center, spacing: 0) {
                    ForEach(self.viewModel.sesameLockCellModels(),
                            id: \.uuid)
                    { sesameLockCellModel in
                        self.sesameLockCell(sesameLockCellModel: sesameLockCellModel, geometry: geometry)
                    }
                }
            }
        }
        .padding(.horizontal)
        .background(Color(UIColor(rgb: 0x222223)))
        .cornerRadius(10.0)
        .frame(height: geometry.size.height)
    }
    
    func sesameLockCell(sesameLockCellModel: Sesame2LockViewModel, geometry: GeometryProxy) -> some View {
        
        return SesameLockViewContainer(viewModel: sesameLockCellModel)
            .frame(minWidth: geometry.size.width * 0.9,
                   maxWidth: geometry.size.width * 0.9,
                   minHeight: geometry.size.height * 0.9,
                   maxHeight: geometry.size.height * 0.9,
                   alignment: .center)
            .padding(.vertical)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(viewModel: .init(deviceProvider: MockDeviceProvider(3)))
//    }
//}
