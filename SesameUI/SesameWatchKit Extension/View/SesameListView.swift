//
//  SesameListView.swift
//  SesameWatchKit Extension
//
//  Created by Wayne Hsiao on 2020/8/4.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import SwiftUI

struct SesameListView: View {
    @ObservedObject var viewModel: SesameListViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.cellViewModels()) { cellModel in
                SesameListCell(viewModel: cellModel)
                    .listStyle(CarouselListStyle())
                    .frame(height: 70)
            }
        }
    }
}

struct SesameListCell: View {
    @ObservedObject var viewModel: SesameListCellModel

    var body: some View {
        Button(action: viewModel.selectDevice, label: {
            HStack {
                Image(viewModel.image)
                    .resizable()
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(viewModel.circleColor, lineWidth: viewModel.circleLineWidth))
                    .scaledToFit()
                Text(viewModel.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.01)
            }
        })
    }
}

