//
//  VersionLabel.swift
//  sesame-sdk-test-app
//
//  Created by Wayne Hsiao on 2020/5/21.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

final class VersionLabel: UIView {
    
    private let textView: UITextView
    private var downloadURL: String?
    
    private lazy var gitPlistContent: [String: Any]? = {
        guard let gitPlist = gitPlist else { return nil }
        return NSDictionary(contentsOfFile: gitPlist) as? [String : Any]
    }()
    
    private lazy var gitPlist: String? = {
        guard let path = Bundle.main.path(forResource: "git", ofType: "plist") else {
            return nil
        }
        return path
    }()
    
    private lazy var commit: String? = {
        gitPlistContent?["GitCommit"] as? String
    }()
    
    init(downloadURL: String? = nil) {
        self.downloadURL = downloadURL
        self.textView = UITextView()
        super.init(frame: .zero)
        
        setupUI()
        setupVersionText()
    }
    
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textAlignment = .center
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.centerXAnchor.constraint(equalTo: centerXAnchor),
            textView.centerYAnchor.constraint(equalTo: centerYAnchor),
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),
            textView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            textView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])
    }
    
    private func setupVersionText() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        let revision = commit ?? ""
        
        let versionText = "\(appVersion)(\(bundleVersion)) - \(revision)"
        
        // 创建属性字符串
        let attributedString = NSMutableAttributedString(string: versionText)
        
        // 设置基础样式
        let fullRange = NSRange(location: 0, length: versionText.count)
        attributedString.addAttributes([
            .font: UIFont(name: "TrebuchetMS", size: 15) ?? UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.placeHolderColor
        ], range: fullRange)
        
        // 如果有 URL，设置链接但不改变样式
        if let url = downloadURL {
            attributedString.addAttribute(.link, value: url, range: fullRange)
            
            // 设置链接样式为默认样式（无下划线，保持原色）
            textView.linkTextAttributes = [
                .foregroundColor: UIColor.placeHolderColor,
                .underlineStyle: 0
            ]
        }
        
        textView.attributedText = attributedString
    }
    
    func updateDownloadURL(_ url: String?) {
        self.downloadURL = url
        setupVersionText()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
