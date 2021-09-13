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

struct Sesame2LockViewContainer: View {
    @ObservedObject var viewModel: Sesame2LockViewModel
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                Image(self.viewModel.bluetoothImage)
                    .resizable()
                    .frame(width: 12, height: 12, alignment: .leading)
                Image(self.viewModel.wifiStatusImage)
                    .resizable()
                    .frame(width: 12, height: 12, alignment: .leading)
                Spacer()
                Image(self.viewModel.batteryImage)
                    .resizable()
                    .frame(width: 15, height: 9, alignment: .leading)
                Text(self.viewModel.batteryPercentage)
                    .font(.footnote)
                    .foregroundColor(Color(UIColor.sesame2LightGray))
            }
            .padding(.trailing, -1)
            VStack() {
                SesameLockView(viewModel: self.viewModel)
                    .frame(width: geometry.size.width * 0.7,
                           height: geometry.size.width * 0.7)
                    .padding(.bottom, -5)
                Text(self.viewModel.display)
                    .lineLimit(1)
                    .minimumScaleFactor(0.01)
                    .frame(width: geometry.size.width,
                           alignment: .center)
                    .padding(.bottom, -5)
            }
            .frame(height: geometry.size.height)
                .onReceive(self.userData.$selectedDevice) { uuid in
            }
            .padding(.bottom, -10)
        }
    }
}

/// Inspired and referenced by this  [post](https://www.raywenderlich.com/5815412-getting-started-with-swiftui-animations).
struct SesameLockView: View {
    @ObservedObject var viewModel: Sesame2LockViewModel
    
    var body: some View {
        GeometryReader { geometry in
            makeSesameCircle(geometry: geometry)
        }
    }
    
    func makeSesameCircle(geometry: GeometryProxy) -> some View {
        let lockSize = geometry.size.height * 1
        let lockIndicatorSize = geometry.size.height * 0.07
        return ZStack {
            if viewModel.deviceType == .sesame2 {
                lockButton(lockSize: .init(width: lockSize, height: lockSize))
                lockIndicator(size: lockIndicatorSize, color: Color(viewModel.lockColor))
                    .modifier(
                        LockMovingEffect(radians: viewModel.radians, radius: lockSize / 2.0)
                    )
            } else if viewModel.deviceType == .sesameBot {
                lockButton(lockSize: .init(width: lockSize, height: lockSize))
            } else if viewModel.deviceType == .bikeLock {
                lockButton(lockSize: .init(width: lockSize, height: lockSize))
            }
        }
    }
    
    func lockButton(lockSize: CGSize) -> some View {
        return Button(action: {
            viewModel.lockTapped()
        }) {
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
    
    func lockIndicator(size: CGFloat,
                       color: Color) -> some View {
        return Circle()
            .fill(color)
            .frame(width: size, height: size, alignment: .center)
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
