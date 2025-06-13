//
//  SesameCell.swift
//  SesameWatchKit Extension
//
//  Created by YuHan Hsiao on 2020/6/3.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import SwiftUI
import SesameWatchKitSDK
import CoreBluetooth

struct SesameLockView: View {
    @ObservedObject var viewModel: SesameLockViewModel
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                HStack() {
                    Image(viewModel.bluetoothImage).resizable().frame(width: 12, height: 12, alignment: .leading)
                    Image(viewModel.wifiStatusImage).resizable().frame(width: 12, height: 12, alignment: .leading)
                    Spacer()
                    ZStack(alignment:.leading, content: {
                        Rectangle().foregroundColor(viewModel.batteryIndicatorColor).frame(width: viewModel.batteryIndicatorWidth, height: 6, alignment: .leading)
                        Image(viewModel.batteryImage).resizable().frame(width: 15, height: 12, alignment: .leading)
                    })
                    Text(viewModel.batteryPercentage)
                        .font(.system(size: 10))
                        .frame(height:12)
                        .foregroundColor(Color(UIColor.sesame2LightGray))
                }
                
                LockView(viewModel: viewModel).frame(width: geometry.size.width * 0.7, height: geometry.size.width * 0.7)
                
                Text(viewModel.display)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: geometry.size.width, alignment: .center)
            }
        }.onDisappear {
            viewModel.prepareDestory()
        }
    }
}

struct LockView: View {
    @ObservedObject var viewModel: SesameLockViewModel
    
    var body: some View {
        GeometryReader { geometry in
            let lockSize = geometry.size.height * 1
            let lockIndicatorSize = geometry.size.height * 0.07
            ZStack {
                lockButton(lockSize: .init(width: lockSize, height: lockSize))
                if viewModel.isCurrentSesameLock {
                    lockIndicator(size: lockIndicatorSize, color: Color(viewModel.lockColor))
                        .modifier(LockMovingEffect(radians: viewModel.radians, radius: lockSize / 2.0))
                }
            }
        }
    }
    

    func lockButton(lockSize: CGSize) -> some View {
        return Button(action: { viewModel.lockTapped() }) {
            Circle()
                .strokeBorder(Color.white, lineWidth: 1)
                .frame(width: lockSize.width, height: lockSize.height, alignment: .center)
                .background(
                    Image(viewModel.imageName)
                        .renderingMode(.original)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                )
        }
        .frame(width: lockSize.width, height: lockSize.height, alignment: .center)
        .cornerRadius(lockSize.width/2)
        .buttonStyle(PlainButtonStyle())
    }
    
    func lockIndicator(size: CGFloat,color: Color) -> some View {
        return Circle().fill(color).frame(width: size, height: size, alignment: .center)
    }
    struct LockMovingEffect: GeometryEffect {
        var radians: CGFloat
        let radius: CGFloat

        var animatableData: CGFloat {
            get { return radians }
            set { radians = newValue }
        }

        func effectValue(size: CGSize) -> ProjectionTransform {
            let to = CGFloat(Double.pi*2) / CGFloat(360) * radians
            let pt = CGPoint(x: cos(to) * radius, y: sin(to) * radius)
            let translation = CGAffineTransform(translationX: pt.x, y: pt.y)
            return ProjectionTransform(translation)
        }
    }
}


