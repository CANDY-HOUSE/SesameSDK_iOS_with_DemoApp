//
//  AddFriendsViewCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/22.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

//public final class AddFriendViewCoordinator: Coordinator {
//    public var childCoordinators: [String : Coordinator] = [:]
//    
//    public weak var presentedViewController: UIViewController?
//    private var navigationController: UINavigationController
//    private var friends: [Sesame2Operator]
//    
//    public init(navigationController: UINavigationController,
//                friends: [Sesame2Operator]) {
//        self.navigationController = navigationController
//        self.friends = friends
//    }
//    
//    public func start() {
//        guard let addFriendViewController = UIStoryboard.viewControllers.addFriendViewController else {
//            return
//        }
//        let viewModel = AddFriendViewModel(currentFriends: friends)
//        viewModel.delegate = self
//        addFriendViewController.viewModel = viewModel
//        presentedViewController = addFriendViewController
//        navigationController.pushViewController(addFriendViewController, animated: true)
//    }
//}
//extension AddFriendViewCoordinator: AddFriendViewModelDelegate {
//    public func addNewFriendTapped() {
//        let scanViewCoordinator = ScanViewCoordinator(navigationController: navigationController)
//        scanViewCoordinator.start()
//    }
//}
