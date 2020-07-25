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
    enum Items {
        static let deviceList = 0
        static let contactsList = 1
        static let me = 2
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = .sesame2Green
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
    }
    
    func userStateChangeAction(_ userState:UserState?) {
        if userState == .signedIn {
//            CHAccountManager.shared.login(identityProvider: AWSMobileClient.default())
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}
