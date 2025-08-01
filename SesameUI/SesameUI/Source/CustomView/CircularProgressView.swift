//
//  CircularProgressView.swift
//  SesameUI
//
//  Created by frey Mac on 2025/8/1.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
            
            // 进度圆环
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeOut(duration: 0.3), value: progress)
            
            // 百分比文字
            Text("\(Int(progress * 100))%")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(width: 100, height: 100)
    }
}
