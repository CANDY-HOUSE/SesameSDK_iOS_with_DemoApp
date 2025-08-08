//
//  CustomInputDialog.swift
//  SesameUI
//
//  Created by frey Mac on 2025/8/8.
//  Copyright © 2025 CandyHouse. All rights reserved.
//

import SwiftUI

struct CustomInputDialog: View {
    var nameLabel: String = "co.candyhouse.sesame2.ssm_name".localized
    var namePlaceholder: String = "co.candyhouse.sesame2.ssm_hint_enter_name".localized
    var passwordLabel: String = "co.candyhouse.sesame2.ssm_password".localized
    var passwordPlaceholder: String = "co.candyhouse.sesame2.ssm_hint_enter_password".localized
    var passwordErrorHint: String = "co.candyhouse.sesame2.ssm_hint_enter_password_tips".localized
    
    @State private var name = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var nameHasError = false
    @State private var passwordHasError = false
    
    var passwordFilter: (String) -> String = { newValue in
        newValue.filter { $0.isNumber }
    }
    var passwordKeyboardType: UIKeyboardType = .numberPad
    
    var onConfirm: ((String, String) -> Void)?
    var onBatchAdd: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    var body: some View {
        ZStack {
            // 背景点击层
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss?()
                }
            
            VStack(spacing: 0) {
                // 名称输入
                VStack(alignment: .leading, spacing: 8) {
                    Text(nameLabel)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    TextField(namePlaceholder, text: $name)
                        .font(.system(size: 16))
                        .padding(.bottom, 8)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(nameHasError ? .red : .black),
                            alignment: .bottom
                        )
                        .onChange(of: name) { _ in
                            nameHasError = false
                        }
                    
                    if nameHasError {
                        Text(namePlaceholder)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                // 密码输入
                VStack(alignment: .leading, spacing: 8) {
                    Text(passwordLabel)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    TextField(passwordPlaceholder, text: $password)
                        .font(.system(size: 16))
                        .keyboardType(passwordKeyboardType)
                        .padding(.bottom, 8)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(passwordHasError ? .red : .black),
                            alignment: .bottom
                        )
                        .onChange(of: password) { newValue in
                            let filtered = passwordFilter(newValue)
                            password = String(filtered.prefix(40))
                            passwordHasError = false
                        }
                    
                    if passwordHasError {
                        Text(passwordErrorHint)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                
                // 按钮
                HStack(spacing: 0) {
                    Button(action: {
                        onDismiss?()
                    }) {
                        Text("co.candyhouse.sesame2.ssm_cancel".localized)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                    }
                    
                    Button(action: {
                        onDismiss?()
                        onBatchAdd?()
                    }) {
                        Text("co.candyhouse.sesame2.ssm_batch_add".localized)
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                    }
                    
                    Button(action: {
                        var hasError = false
                        
                        if name.isEmpty {
                            nameHasError = true
                            hasError = true
                        }
                        
                        if password.isEmpty {
                            passwordHasError = true
                            hasError = true
                        }
                        
                        if !hasError {
                            onDismiss?()
                            onConfirm?(name, password)
                        }
                    }) {
                        Text("co.candyhouse.sesame2.ssm_confirm".localized)
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                    }
                }
                .frame(height: 50)
            }
            .frame(width: 350)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 10)
            .onTapGesture {
                // 防止点击对话框内部也关闭
            }
        }
    }
}
