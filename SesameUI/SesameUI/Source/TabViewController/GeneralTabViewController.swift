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
import AWSMobileClientXCF

public class GeneralTabViewController: UITabBarController {
    
    fileprivate var sesame2TabBarItem: UITabBarItem!
    fileprivate var meTabBarItem: UITabBarItem!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.tintColor = .sesame2Green
        tabBar.layer.borderWidth = 0
        tabBar.clipsToBounds = true
        tabBar.selectedItem?.title = "selected"
        
        // 當 AWS Mobile 啟動時 執行以下服務
        AWSMobileClient.default().initialize { (userState, error) in
            // 1. 設定並啟動 API manager
            CHAPIClient.initialize(credentialsProvider: AWSMobileClient.default())
            AppPromotionManager.shared.refresh()
            
            // 2. 判斷是否第一次安裝
            if UserDefaults.standard.bool(forKey: "HasInstalled") == false {
                UserDefaults.standard.set(true, forKey: "HasInstalled")
                CHAWSMobileClient.shared.signOut()
            }
            if userState == .signedIn {
                // 3. 設定 history tag
                CHAWSMobileClient.shared.getName { result in
                    if case let .success(nickname) = result {
                        Sesame2Store.shared.setHistoryTag(nickname)
                    }
                }
                CHAPIClient.shared.uploadUserDeviceToken() { result in}
            }
        }
        
        // 當用戶登出登入時，執行以下服務
        AWSMobileClient.default().addUserStateListener(self) { state, dic in
            if state == .signedIn {
                CHAPIClient.shared.uploadUserDeviceToken() { _ in }
                AppPromotionManager.shared.refresh()
                CHAWSMobileClient.shared.getName { result in
                    if case let .success(nickname) = result {
                        Sesame2Store.shared.setHistoryTag(nickname)
                    }
                }
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePromotionChanged(_:)),
            name: AppPromotionManager.promotionChangedNotification,
            object: nil
        )
        updatePromotionBadge(AppPromotionManager.shared.currentPromotion)
    }
    
    public override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item.title == "co.candyhouse.sesame2.Me".localized {
            tabBar.barTintColor = .sesame2Gray
        } else {
            tabBar.barTintColor = .white
        }
    }

    @objc private func handlePromotionChanged(_ notification: Notification) {
        let promotion = notification.object as? AppPromotion
        updatePromotionBadge(promotion)
    }

    private func updatePromotionBadge(_ promotion: AppPromotion?) {
        executeOnMainThread { [weak self] in
            guard let self = self else { return }
            self.meTabBarItem?.badgeColor = .red
            self.meTabBarItem?.badgeValue = promotion?.visible == true ? "" : nil
        }
    }
}

// MARK: - Designated initializer
extension GeneralTabViewController {
    /// 指定初始方法，產生 instance 並設定 content view controllers
    static func instance() -> GeneralTabViewController {
        let meViewController = MeViewController.instance()
        let friendListViewController = FriendViewController.instance()
        let sesame2ListViewController = SesameDeviceListViewController.instance()
        let visionViewController = VisionViewController.instance()
        
        let deviceListItem = UITabBarItem(title: "co.candyhouse.sesame2.Sesame".localized,
                                          image: UIImage.SVGImage(named:"keychain_original"),
                                          selectedImage: UIImage.SVGImage(named:"keychain_tint"))
        
        let visionItem = UITabBarItem(title: "co.candyhouse.sesame2.Vision".localized,
                                      image: UIImage.SVGImage(named:"vision"),
                                      selectedImage: UIImage.SVGImage(named:"vision",fillColor: .sesame2Green))
        
        let friendListItem = UITabBarItem(title: "co.candyhouse.sesame2.Contacts".localized,
                                          image: UIImage.SVGImage(named:"friends"),
                                          selectedImage: UIImage.SVGImage(named:"friends_filled"))
        
        let meItem = UITabBarItem(title: "co.candyhouse.sesame2.Me".localized,
                                  image: UIImage.SVGImage(named:"icons_outlined_me",fillColor: UIColor.gray),
                                  selectedImage: UIImage.SVGImage(named:"icons_filled_official-accounts",fillColor: .sesame2Green))

        sesame2ListViewController.tabBarItem = deviceListItem
        visionViewController.tabBarItem = visionItem
        friendListViewController.tabBarItem = friendListItem
        meViewController.tabBarItem = meItem

        let entryViewController = GeneralTabViewController(nibName: nil, bundle: nil)
        entryViewController.meTabBarItem = meItem
        entryViewController.setViewControllers([
            sesame2ListViewController.navigationController!,
            visionViewController.navigationController!,
            friendListViewController.navigationController!,
            meViewController.navigationController!
        ], animated: false)
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
