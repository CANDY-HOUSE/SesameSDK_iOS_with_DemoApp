//
//  WebViewScreen.swift
//  SesameUI
//
//  Created by frey Mac on 2025/7/22.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import SwiftUI
import WebKit

// WebView 视图
struct WebViewScreen: View {
    let urlString: String
    let isModal: Bool
    @State private var isLoading = true
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                if let url = URL(string: urlString) {
                    WebView(url: url, isLoading: $isLoading)
                }
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .navigationBarItems(leading: isModal ? Button("Close") {
                presentationMode.wrappedValue.dismiss()
            } : nil)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
