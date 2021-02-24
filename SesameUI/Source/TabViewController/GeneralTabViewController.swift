//
//  GeneralTabViewController.swift
//  sesame-sdk-test-app
//
//  Created by Yiling on 2019/08/30.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

public class GeneralTabViewController: UITabBarController {
    
    fileprivate var sesame2TabBarItem: UITabBarItem! {
        didSet {
            sesame2TabBarItem.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        }
    }
    fileprivate var meTabBarItem: UITabBarItem!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = .sesame2Green
        tabBar.layer.borderWidth = 0
        tabBar.clipsToBounds = true
        tabBar.selectedItem?.title = "selected"
    }
    
    public override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.title == "co.candyhouse.sesame2.Me".localized {
            tabBar.barTintColor = .sesame2Gray
        } else {
            tabBar.barTintColor = .white
        }
    }
}

// MARK: - Designated initializer
extension GeneralTabViewController {
    static func instance() -> GeneralTabViewController {
        let sesame2ListViewController = SesameDeviceListViewController.instance()
        
        let deviceListItem = UITabBarItem(title: "co.candyhouse.sesame2.Sesame".localized,
                                          image: UIImage.SVGImage(named:"keychain_original"),
                                          selectedImage: UIImage.SVGImage(named:"keychain_tint"))

        sesame2ListViewController.tabBarItem = deviceListItem

        let entryViewController = GeneralTabViewController(nibName: nil, bundle: nil)
        entryViewController.setViewControllers([sesame2ListViewController.navigationController!], animated: false)
        entryViewController.tabBar.barTintColor = .white
        return entryViewController
    }
}

extension GeneralTabViewController {
    @discardableResult
    static func switchTabByIndex(_ index: Int) -> UIViewController? {
        if let navigationViewController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController,
           let generalTabViewController = navigationViewController.viewControllers.first as? GeneralTabViewController {
            generalTabViewController.selectedViewController = generalTabViewController.viewControllers?[index]
            return generalTabViewController.selectedViewController
        } else {
            return nil
        }
    }
    
    static func getTabViewControllersBy(_ index: Int) -> UIViewController? {
        if let navigationViewController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController,
           let generalTabViewController = navigationViewController.viewControllers.first as? GeneralTabViewController {
            return generalTabViewController.viewControllers?[index]
        } else {
            return nil
        }
    }
}
