//
//  SesameListCell.swift
//  SesameWatchKit Extension
//
//  Created by Wayne Hsiao on 2020/8/4.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import SwiftUI

struct Sesame2ListCell: View {
    @ObservedObject var viewModel: Sesame2ListCellModel
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        GeometryReader { geometry in
            self.contentView(geometry: geometry)
                .frame(width: geometry.size.width, height: geometry.size.height,
                       alignment: .center)
                .onTapGesture {
                    self.userData.selectedDevice = self.viewModel.uuid
            }
        }
    }
    
    func contentView(geometry: GeometryProxy) -> some View {
        var circleColor = UIColor.sesame2Green
        var circleLineWidth = CGFloat(0)
        if let selectedId = userData.selectedDevice,
            viewModel.isSelected(uuid: selectedId) == true {
            circleColor = UIColor.sesame2LightGray
            circleLineWidth = 2
        }
        return HStack {
            Image(viewModel.image)
                .resizable()
                .frame(width: 45, height: 45)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(circleColor), lineWidth: circleLineWidth))
                .scaledToFit()
            Text(viewModel.title)
                .lineLimit(1)
                .minimumScaleFactor(0.01)
        }
    }
}

//struct SesameListCell_Previews: PreviewProvider {
//    static var previews: some View {
//        SesameListViewCell()
//    }
//}
