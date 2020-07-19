//
//  GeneralTabViewCoordinator.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/18.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

public class GeneralTabViewCoordinator: Coordinator {
    public var childCoordinators: [String: Coordinator] = [:]
    public var parentCoordinator: Coordinator?
    public weak var presentedViewController: UIViewController?
    
    let navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    public func start() {
        let bluetoothListCoordinator = BluetoothDevicesListCoordinator(navigationViewController: UINavigationController())
        bluetoothListCoordinator.parentCoordinator = self
        bluetoothListCoordinator.start()
        
        let friendsViewControllerCoordinator = FriendsViewControllerCoordinator(navigationController: UINavigationController())
        friendsViewControllerCoordinator.parentCoordinator = self
        friendsViewControllerCoordinator.start()
        
        let meViewCoordinator = MeViewCoordinator(navigationController: UINavigationController())
        meViewCoordinator.parentCoordinator = self
        meViewCoordinator.start()
        
        guard let entryViewController = UIStoryboard.viewControllers.generalTabViewController,
            let deviceListViewController = bluetoothListCoordinator.presentedViewController,
            let friendListViewController = friendsViewControllerCoordinator.presentedViewController,
            let meViewController = meViewCoordinator.presentedViewController else {
                return
        }
        
        let deviceListItem = UITabBarItem(title: "Sesame".localStr,
                                          image: UIImage.SVGImage(named:"keychain_original"),
                                          selectedImage: UIImage.SVGImage(named:"keychain_tint"))
        
        let contactItem = UITabBarItem(title: "Contacts".localStr,
                                       image: UIImage.SVGImage(named:"icons_outlined_contacts",fillColor: UIColor.gray),
                                       selectedImage: UIImage.SVGImage(named:"icons_filled_contacts",fillColor: .sesame2Green))
        
        let meItem = UITabBarItem(title: "Me".localStr,
                                  image: UIImage.SVGImage(named:"icons_outlined_me",fillColor: UIColor.gray),
                                  selectedImage: UIImage.SVGImage(named:"icons_filled_official-accounts",fillColor: .sesame2Green))
        
        
        deviceListViewController.tabBarItem = deviceListItem
        friendListViewController.tabBarItem = contactItem
        meViewController.tabBarItem = meItem

        entryViewController.setViewControllers([bluetoothListCoordinator.navigationController,
                                                friendsViewControllerCoordinator.navigationController,
                                                meViewCoordinator.navigationController],
                                               animated: false)
        
        navigationController.pushViewController(entryViewController, animated: false)
        presentedViewController = entryViewController
    }
    
    public func childCoordinatorDismissed(_ coordinator: Coordinator, userInfo: [String: Any]) {
        if (coordinator as? BluetoothDevicesListCoordinator) != nil ||
            (coordinator as? FriendsViewControllerCoordinator) != nil ||
            (coordinator as? MeViewCoordinator) != nil {
            (presentedViewController as? UITabBarController)?.selectedIndex = 0
        }
    }
}
