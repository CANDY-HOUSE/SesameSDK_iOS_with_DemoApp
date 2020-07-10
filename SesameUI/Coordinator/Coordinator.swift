//
//  Coordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/18.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

public protocol Coordinator {
    var childCoordinators: [String: Coordinator] { get }
    var parentCoordinator: Coordinator? { get set }
    var presentedViewController: UIViewController? { get }
    func start()
    func childCoordinatorDismissed(_ coordinator: Coordinator, userInfo: [String: Any])
}

extension Coordinator {
    public func childCoordinatorDismissed(_ coordinator: Coordinator, userInfo: [String: Any]) {

    }
}
