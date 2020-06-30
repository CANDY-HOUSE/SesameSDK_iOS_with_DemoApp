//
//  GeneralTabViewController.swift
//  sesame-sdk-test-app
//
//  Created by Yiling on 2019/08/30.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK
import AWSAPIGateway
import AWSMobileClient

public class GeneralTabViewController: UITabBarController {
    enum Items {
        static let deviceList = 0
        static let contactsList = 1
        static let me = 2
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabBar.tintColor = .sesameGreen
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()
        tabBar.layer.borderWidth = 0
        tabBar.clipsToBounds = true

        AWSMobileClient.default().initialize { (userState, error) in
            L.d("🧕 initialize",userState as Any,AWSMobileClient.default().isSignedIn)
            self.userStateChangeAction(userState)
        }
        AWSMobileClient.default().addUserStateListener(self) { (userState, info) in
            L.d("🧕","StateListen",userState)
            self.userStateChangeAction(userState)
        }
        
        NotificationCenter
            .default
            .addObserver(forName: .SesameRegistered,
                         object: nil,
                         queue: OperationQueue.main) { [weak self] _ in
                            guard let strongSelf = self else {
                                    return
                            }
                            strongSelf.selectedIndex = 0
                            
        }
    }
    
    func userStateChangeAction(_ userState:UserState?) {
        if userState == .signedIn {
//            CHAccountManager.shared.login(identityProvider: AWSMobileClient.default())
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
            DispatchQueue.main.async {
                L.d("登入成功刷新個頁面狀態")
                NotificationCenter.default.post(name: .UserLoggedIn, object: nil)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension GeneralTabViewController: UITabBarControllerDelegate {
    public override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        switch self.tabBar.items?.firstIndex(of: item) {
        case Items.deviceList:
            break
        case Items.contactsList:
//            guard AWSMobileClient.default().isSignedIn == true else {
//                self.gotoLoginPage()
//                return
//            }
            break
        case Items.me:
            break
        default:
            break
        }
    }
    
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
//        if let navigationViewController = viewController as? UINavigationController,
//            let _ = navigationViewController.viewControllers.first as? FriendsViewController {
//            return AWSMobileClient.default().isLoggedIn
//        }
        return true
    }
}
