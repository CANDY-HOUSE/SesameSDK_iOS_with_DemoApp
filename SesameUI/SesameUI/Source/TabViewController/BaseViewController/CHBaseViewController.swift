//
//  CHBaseVC.swift
//  sesame-sdk-test-app
//  [navigation views]
//  Created by tse on 2020/3/28.
//  Copyright © 2020 CandyHouse. All rights reserved.
//
import UIKit
import AVFoundation
import SesameSDK
import CoreBluetooth
import Foundation

public class CHBaseViewController: UIViewController, CHRouteCoordinator, PopUpMenuDelegate {
    @objc  func handleRightBarButtonTapped(_ sender: Any) {
        if self.popUpMenuControl.superview != nil {
            popUpMenuControl.hide(animated: true)

        } else {
            popUpMenuControl.show(in: UIApplication.shared.keyWindow!)
        }
    }

    func popUpMenu(_ menu: PopUpMenu, didTap item: PopUpMenuItem) { // 點擊(+)按鈕
        switch item.type {
        case .addSesame2:
            presentRegisterSesame2ViewController()
        case .receiveKey:
            presentScanViewController()
        case .findFriend:
            presentFindFriendsViewController { [weak self] newVal in
                guard let self = self else { return }
                ViewHelper.showLoadingInView(view: self.view)
                FindFriendHandler.shared.addFriendByEmail(newVal.trimmingCharacters(in: .whitespacesAndNewlines)) { [weak self] (friend, err) in
                    guard let self = self else { return }
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
                        if let error = err {
                            self.view.makeToast(error.errorDescription())
                        } else {
                            // 進入詳情
                            if let navController = GeneralTabViewController.getTabViewControllersBy(1) as? UINavigationController, let listViewController = navController.viewControllers.first as? FriendListViewController {
                                if listViewController.isViewLoaded {
                                    listViewController.getFriends()
                                }
                            }
                            let friendKeyListViewController = FriendKeyListViewController.instance(friend!) { _ in }
                            self.navigationController?.pushViewController(friendKeyListViewController, animated: true)
                        }
                    }
                }
            }
        }
        popUpMenuControl.hide(animated:false)

    }
    
    // MARK: - UI components
    lazy var popUpMenuControl: PopUpMenuControl = {
        let y = UIApplication.shared.statusBarFrame.height + 25
        let frame = CGRect(x: 0, y: y, width: view.bounds.width, height: view.bounds.height - y)
        let popUpMenuControl = PopUpMenuControl(frame: frame)
        popUpMenuControl.delegate = self
        return popUpMenuControl
    }()
    // MARK: - Properties
    private var previouseNavigationTitle = ""
    
    public override var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    var soundPlayer: AVAudioPlayer?
    var navigationBarBackgroundColor: UIColor = .white
    
    // MARK: - UI Components
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: .zero)
        view.addSubview(titleLabel)
        titleLabel.autoPinLeading()
        titleLabel.autoPinTrailing()
        titleLabel.autoPinCenterY()
        titleLabel.autoLayoutHeight(40)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.minimumScaleFactor = 0.01
        return titleLabel
    }()

    // MARK: - Life cycle
#if DEBUG
    deinit {
        L.d(" ===================== \(type(of: self)) deinit ===================== ")
    }
#endif
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        _ = BleHelper.shared // 初始化UI端的藍芽
        view.backgroundColor = .sesame2Gray
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance.shadowColor = .clear
        } else {
//            移除 navigation bar borders 的方法，在 ios 13 以上無效
//            https://try2explore.com/questions/10105773
            let navigationBar = navigationController?.navigationBar
            navigationBar?.shadowImage = UIImage()
        }
        
        if #available(iOS 12.0, *) {
            navigationItem.titleView = titleLabel
        } else {
            titleLabel.removeFromSuperview()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance.backgroundColor = navigationBarBackgroundColor
            navigationController?.navigationBar.scrollEdgeAppearance = navigationController?.navigationBar.standardAppearance
                //移除置頂是白色。畫面向下滑動變黑的特性
        } else {
            navigationController?.navigationBar.barTintColor = navigationBarBackgroundColor
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        previouseNavigationTitle = titleLabel.text ?? ""
        navigationItem.title = ""
    }
    
    public func didBecomeActive() {
        /// 給繼承類 override 用
    }

    var secondSettingValue: [Int] {
        [0, 3, 5, 7, 10, 15, 30, 60, 60*2, 60*3, 60*4, 60*5, 60*10, 60*15, 60*30, 60*60]
    }
    
    var opsSecondSettingValue: [Int] {
        [65535, 0, 1, 2, 3, 4, 5, 7, 10, 15, 30, 60, 60*2, 60*3, 60*4, 60*5, 60*10, 60*15, 60*30, 60*60]
    }
    
    // MARK: formatedTimeFromSec
    func formatedTimeFromSec(_ sec: Int) -> String {
        if sec > 0 && sec < 60 {
            return "\(sec) \("co.candyhouse.sesame2.sec".localized)"
        } else if sec >= 60 && sec < 60*60 {
            return "\(sec/60) \("co.candyhouse.sesame2.min".localized)"
        } else if sec == 65535 {
            return "\("co.candyhouse.sesame2.immediately".localized)"
        } else if sec >= 60*60 {
            return "\(sec/(60*60)) \("co.candyhouse.sesame2.hour".localized)"
        }  else {
            return "co.candyhouse.sesame2.off".localized
        }
    }
}
