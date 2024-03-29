//
//  VersionLabel.swift
//  sesame-sdk-test-app
//
//  Created by Wayne Hsiao on 2020/5/21.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

final class VersionLabel: UILabel {
    
    private lazy var gitPlist: String? = {
        guard let path = Bundle.main.path(forResource: "git", ofType: "plist") else {
            return nil
        }
        return path
    }()
    
    private lazy var gitPlistContent: [String: Any]? = {
        guard let gitPlist = gitPlist else {
            return nil
        }
        return NSDictionary(contentsOfFile: gitPlist) as? [String : Any] ?? nil
    }()
    
    private lazy var commit: String? = {
        gitPlistContent?["GitCommit"] as? String ?? nil
    }()

    init() {
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        textAlignment = .center
        font = UIFont(name: "TrebuchetMS", size: 15)
        textColor = UIColor.placeHolderColor
        sizeToFit()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        let revision = commit ?? ""
        text = "\(appVersion)(\(bundleVersion)) - \(revision)"
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("Please invoke designated initializer init() instead.")
    }
    
}
