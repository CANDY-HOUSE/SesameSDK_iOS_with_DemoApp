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
    
    fileprivate var sesame2TabBarItem: UITabBarItem!
    public override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = .sesame2Green
        tabBar.layer.borderWidth = 0
        tabBar.clipsToBounds = true
        tabBar.selectedItem?.title = "selected"
    }
}

// MARK: - Designated initializer
extension GeneralTabViewController {
    /// 指定初始方法，產生 instance 並設定 content view controllers
    static func instance() -> GeneralTabViewController {
        let sesame2ListViewController = SesameDeviceListViewController.instance()
        
        let deviceListItem = UITabBarItem(title: "co.candyhouse.sesame2.Sesame".localized,
                                          image: UIImage.SVGImage(named:"keychain_original"),
                                          selectedImage: UIImage.SVGImage(named:"keychain_tint"))

        sesame2ListViewController.tabBarItem = deviceListItem
        let entryViewController = GeneralTabViewController(nibName: nil, bundle: nil)
        entryViewController.setViewControllers([
            sesame2ListViewController.navigationController!], animated: false)
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
