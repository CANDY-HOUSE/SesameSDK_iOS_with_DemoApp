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

struct SesameLockViewContainer: View {
    @ObservedObject var viewModel: Sesame2LockViewModel
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Image(self.viewModel.batteryImage)
                        .resizable()
                        .frame(width: 15, height: 9, alignment: .leading)
                    Text(self.viewModel.batteryPercentage)
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.sesame2LightGray))
                    Spacer()
                }
                Text(self.viewModel.display)
                    .lineLimit(1)
                    .minimumScaleFactor(0.01)
                SesameLockView(viewModel: self.viewModel)
                    .frame(width: geometry.size.width * 0.5,
                           height: geometry.size.width * 0.5)
                    .padding()
            }
            .padding()
        }
    }
}

/// Inspired and referenced by this  [post](https://www.raywenderlich.com/5815412-getting-started-with-swiftui-animations).
struct SesameLockView: View {
    @ObservedObject var viewModel: Sesame2LockViewModel
    
    var body: some View {
        GeometryReader { geometry in
            self.makePlanet(geometry: geometry)
        }
    }
    
    func makePlanet(geometry: GeometryProxy) -> some View {
        let lockSize = geometry.size.height * 1
        let lockIndicatorSize = geometry.size.height * 0.15
        return ZStack {
            Button(action: {
                self.viewModel.cellTapped()
            }) {
                Image(viewModel.imageName)
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: lockSize,
                           height: lockSize,
                           alignment: .center)
                    .cornerRadius(lockSize/2)
            }
            .frame(width: lockSize,
                   height: lockSize,
                   alignment: .center)
            .cornerRadius(lockSize/2)
            self.lockIndicator(size: lockIndicatorSize,
                               color: Color(self.viewModel.moonColor))
                .modifier(
                    LockMovingEffect(radians: self.viewModel.radians,
                                     radius: lockSize / 2.0)
            )
//                .animation(Animation
//                    .linear(duration: 1.0)
//                    .repeatCount(0, autoreverses: false)
//            )
        }
    }
    
    func lockIndicator(size: CGFloat,
                       color: Color) -> some View {
        return Circle()
            .fill(color)
            .frame(width: size,
                   height: size,
                   alignment: .center)
    }
}

struct LockMovingEffect: GeometryEffect {
    var radians: CGFloat
    let radius: CGFloat
    
    var animatableData: CGFloat {
        get {
            return radians
        }
        set {
            radians = newValue
        }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let to = CGFloat(Double.pi*2) / CGFloat(360) * radians
        let pt = CGPoint(x: cos(to) * radius,
                         y: sin(to) * radius)
        let translation = CGAffineTransform(translationX: pt.x,
                                            y: pt.y)
        return ProjectionTransform(translation)
    }
}


//struct SesameLockCell_Previews: PreviewProvider {
//    static var previews: some View {
//        let mockDevice = MockBleDevice()   //CHBleManager.shared.mockSesame2()
//        let sesame2LockCellModel = Sesame2LockViewModel(device: mockDevice)
//        return SesameLockViewContainer(viewModel: sesame2LockCellModel)
//    }
//}
