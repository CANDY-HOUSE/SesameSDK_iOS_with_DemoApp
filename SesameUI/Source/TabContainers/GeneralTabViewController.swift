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
import AWSAPIGateway
import AWSMobileClient

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
        
        AWSMobileClient.default().initialize { (userState, error) in
            L.d("🧕 initialize",userState as Any,AWSMobileClient.default().isSignedIn)
            self.userStateChangeAction(userState)
        }
        AWSMobileClient.default().addUserStateListener(self) { (userState, info) in
            L.d("🧕","StateListen",userState)
            self.userStateChangeAction(userState)
        }
    }
    
    func userStateChangeAction(_ userState:UserState?) {
        if userState == .signedIn {
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    public override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.title == "co.candyhouse.sesame-sdk-test-app.Me".localized {
            tabBar.barTintColor = .sesame2Gray
        } else if item.title == "co.candyhouse.sesame-sdk-test-app.Sesame".localized {
            tabBar.barTintColor = .white
        }
    }
}

// MARK: - Designated initializer
extension GeneralTabViewController {
    static func instance() -> GeneralTabViewController {
        let meViewController = MeViewController.instance()
        let sesame2ListViewController = Sesame2ListViewController.instance()
        
        let deviceListItem = UITabBarItem(title: "co.candyhouse.sesame-sdk-test-app.Sesame".localized,
                                          image: UIImage.SVGImage(named:"keychain_original"),
                                          selectedImage: UIImage.SVGImage(named:"keychain_tint"))
        
        let meItem = UITabBarItem(title: "co.candyhouse.sesame-sdk-test-app.Me".localized,
                                  image: UIImage.SVGImage(named:"icons_outlined_me",fillColor: UIColor.gray),
                                  selectedImage: UIImage.SVGImage(named:"icons_filled_official-accounts",fillColor: .sesame2Green))

        sesame2ListViewController.tabBarItem = deviceListItem
        meViewController.tabBarItem = meItem

        let entryViewController = GeneralTabViewController(nibName: nil, bundle: nil)
        entryViewController.setViewControllers([
            sesame2ListViewController.navigationController!,
            meViewController.navigationController!
            ],
                                               animated: false)
        entryViewController.tabBar.barTintColor = .white
        return entryViewController
    }
}
