//
//  ContentView.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/5/30.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var tabSelectIndex = 1

    var body: some View {
        if viewModel.haveContent == true {
            // 有 Sesame 畫面
            TabView(selection: $tabSelectIndex) {
                SesameListView(viewModel: viewModel.listViewModel()).tag(0)
                SesameLockView(viewModel: viewModel.lockViewModel()).tag(1)
            }
            .tabViewStyle(PageTabViewStyle())
            .onReceive(self.viewModel.$selectedUUID) { _ in
                // 在 sesame 列表選擇設備時，切換到設備操作畫面
                self.tabSelectIndex = 1
            }
            .onAppear {
                _ = BleHelper.shared
            }
        } else {
            // 沒有 sesame 畫面
            VStack {
                Spacer()
                Text(viewModel.displayText)
                    .foregroundColor(Color(.white))
                    .font(.headline)
                Spacer()
            }
        }
    }
}
