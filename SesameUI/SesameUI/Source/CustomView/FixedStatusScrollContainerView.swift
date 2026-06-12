//
//  FixedStatusScrollContainerView.swift
//  SesameUI
//
//  Created by frey Mac on 2026/6/12.
//  Copyright © 2026 CandyHouse. All rights reserved.
//

import UIKit

final class FixedStatusScrollContainerView: UIView {
    
    let rootStackView = UIStackView(frame: .zero)
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)
    let statusView: CHUIPlainSettingView
    
    private let statusViewHeight: CGFloat
    
    init(statusViewHeight: CGFloat = 64) {
        self.statusViewHeight = statusViewHeight
        self.statusView = CHUIViewGenerator.plain()
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        self.statusViewHeight = 64
        self.statusView = CHUIViewGenerator.plain()
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        
        // MARK: top status
        statusView.backgroundColor = .lockRed
        statusView.title = ""
        statusView.setColor(.white)
        statusView.isHidden = true
        statusView.translatesAutoresizingMaskIntoConstraints = false
        
        let statusViewHeightConstraint = statusView.heightAnchor.constraint(equalToConstant: statusViewHeight)
        statusViewHeightConstraint.priority = .defaultHigh
        statusViewHeightConstraint.isActive = true
        
        // MARK: root stack
        rootStackView.axis = .vertical
        rootStackView.alignment = .fill
        rootStackView.spacing = 0
        rootStackView.distribution = .fill
        rootStackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(rootStackView)
        
        NSLayoutConstraint.activate([
            rootStackView.topAnchor.constraint(equalTo: topAnchor),
            rootStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            rootStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rootStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        rootStackView.addArrangedSubview(statusView)
        rootStackView.addArrangedSubview(scrollView)
        
        // MARK: scroll content
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 0
        contentStackView.distribution = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    func attach(to parentView: UIView) {
        parentView.addSubview(self)
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor),
            leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])
    }
}
