//
//  VisionViewController.swift
//  SesameUI
//
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import UIKit

extension VisionViewController {
    static func instance() -> VisionViewController {
        let vc = VisionViewController(nibName: nil, bundle: nil)
        UINavigationController().pushViewController(vc, animated: false)
        return vc
    }
}

class VisionViewController: CHWebHostViewController {
    override var webScene: String? { "vision" }
    override var reloadAndPopNotifyName: String? { "VisionChanged" }
}
