//
//  DeleteFriendsViewCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

//public final class DeleteFriendsViewCoordinator: Coordinator {
//    public var childCoordinators: [String : Coordinator] = [:]
//    
//    public weak var presentedViewController: UIViewController?
//    private var navigationController: UINavigationController
//    
//    public init(navigationController: UINavigationController) {
//        self.navigationController = navigationController
//    }
//    
//    public func start() {
//        guard let deleteFriendViewController = UIStoryboard.viewControllers.deleteFriendVC else {
//            return
//        }
//        let viewModel = DeleteFriendViewModel()
//        deleteFriendViewController.viewModel = viewModel
//        navigationController.pushViewController(deleteFriendViewController, animated: true)
//    }
//}
