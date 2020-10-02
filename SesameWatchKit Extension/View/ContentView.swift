//
//  ContentView.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/5/30.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel()
    @State var userData = UserData.shared

    var body: some View {
        GeometryReader { geometry in
            if self.viewModel.isShowContent {
                self.container(geometry: geometry)
                .onReceive(self.userData.$selectedDevice) { _ in
                    self.viewModel.deviceHasSelected()
                }
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
    
    func container(geometry: GeometryProxy) -> some View {
        ScrollView (.horizontal, showsIndicators: true) {
             HStack {
                sesame2sListView(geometry: geometry)
                sesame2LockView(geometry: geometry)
             }
        }
    }
    
    func sesame2sListView(geometry: GeometryProxy) -> some View {
        Sesame2ListView(viewModel: viewModel.sesame2ListViewModel())
            .environmentObject(userData)
            .frame(width: geometry.size.width)
    }
    
    func sesame2LockView(geometry: GeometryProxy) -> some View {
        Sesame2LockViewContainer(viewModel: viewModel.selectedSesameLockCellModel())
            .frame(minWidth: geometry.size.width,
                   maxWidth: geometry.size.width,
                   minHeight: geometry.size.height,
                   maxHeight: geometry.size.height,
                   alignment: .center)
            .environmentObject(self.userData)
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(viewModel: .init(deviceProvider: MockDeviceProvider(3)))
//    }
//}
