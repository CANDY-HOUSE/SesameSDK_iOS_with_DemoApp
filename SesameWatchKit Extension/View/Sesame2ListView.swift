//
//  SesameListView.swift
//  SesameWatchKit Extension
//
//  Created by Wayne Hsiao on 2020/8/4.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import SwiftUI

struct Sesame2ListView: View {
    @ObservedObject var viewModel: Sesame2ListViewModel
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        
        GeometryReader { geometry in
            List {
                ForEach(self.viewModel.cellViewModels(),
                               id: \.uuid)
                { cellModel in
                    Sesame2ListCell(viewModel: cellModel)
                        .environmentObject(self.userData)
                        .listStyle(CarouselListStyle())
                        .frame(height: 70)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                if self.userData.selectedDevice == nil {
                    self.userData.selectedDevice = self.viewModel.cellViewModels().first?.uuid
                }
            }
            .onReceive(self.userData.$selectedDevice) { uuid in
                if uuid == nil {
                    self.userData.selectedDevice = self.viewModel.cellViewModels().first?.uuid
                }
            }
        }
    }
}

//struct SesameListView_Previews: PreviewProvider {
//    static var previews: some View {
//        SesameListView()
//    }
//}
