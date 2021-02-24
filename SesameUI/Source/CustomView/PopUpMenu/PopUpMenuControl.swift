//
//  SessionMoreMenuFloatView.swift
//
//  Created by xu.shuifeng on 2019/7/18.
//  Copyright © 2019 alexiscn. All rights reserved.
//

import UIKit

class PopUpMenuControl: UIButton {
    
    var delegate: PopUpMenuDelegate? {
        didSet {
            menuView?.delegate = delegate
        }
    }
    
    private var menuView: PopUpMenu?
    private var menuViewFrame: CGRect = .zero
    
    private var menus: [PopUpMenuItem] = []
    
    let menuWidth: CGFloat = 210.0
    let menuHeight: CGFloat = 56.0
    let paddingTop: CGFloat = 10.0
    let paddingRight: CGFloat = 8.0
    var previousOrientation = "UIInterfaceOrientationPortrait"
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        let addSesame2 = PopUpMenuItem(type: .addSesame2,
                                       title: "co.candyhouse.sesame2.NewSesame".localized,
                                       icon: "cube")
        
        let scanDeviceQRCode = PopUpMenuItem(type: .receiveKey,
                                             title: "co.candyhouse.sesame2.scanQRCode".localized,
                                          icon: "qr-code-scan")

        menus = [
            addSesame2,
            scanDeviceQRCode
        ]

        let menuView = PopUpMenu(itemHeight: menuHeight, itemWidth: menuWidth, menus: menus)
        menuView.frame.origin = CGPoint(x: frame.width - menuWidth - paddingRight, y: paddingTop)
        menuView.transform = .identity
        menuView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(menuView)
        
        self.menuViewFrame = menuView.frame
        self.menuView = menuView
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged),
                                                   name: UIDevice.orientationDidChangeNotification,
                                                   object: nil)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func menuTemplate() -> PopUpMenu {
        let menuView = PopUpMenu(itemHeight: self.menuHeight, itemWidth: self.menuWidth, menus: self.menus)
        menuView.transform = .identity
        menuView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return menuView
    }
    
    @objc func orientationChanged() {
        if let supportedOrientations = Bundle.resourceBundle.object(forInfoDictionaryKey: "UISupportedInterfaceOrientations") as? [String] {
            
            switch UIDevice.current.orientation {
            case .portrait:
                if supportedOrientations.contains("UIInterfaceOrientationPortrait"),
                    supportedOrientations.contains(previousOrientation) {
                    resetMenuFrameAfterRotate()
                }
                previousOrientation = "UIInterfaceOrientationPortrait"
            case .portraitUpsideDown:
                if supportedOrientations.contains("UIInterfaceOrientationPortraitUpsideDown"),
                    supportedOrientations.contains(previousOrientation) {
                    resetMenuFrameAfterRotate()
                }
                previousOrientation = "UIInterfaceOrientationPortraitUpsideDown"
            case .landscapeLeft:
                if supportedOrientations.contains("UIInterfaceOrientationLandscapeLeft"),
                    supportedOrientations.contains(previousOrientation) {
                    resetMenuFrameAfterRotate()
                }
                previousOrientation = "UIInterfaceOrientationLandscapeLeft"
            case .landscapeRight:
                if supportedOrientations.contains("UIInterfaceOrientationLandscapeRight"),
                    supportedOrientations.contains(previousOrientation) {
                    resetMenuFrameAfterRotate()
                }
                previousOrientation = "UIInterfaceOrientationLandscapeRight"
            case .faceUp:
                break
            case .faceDown:
                break
            case .unknown:
                break
            @unknown default:
                break
            }
        }
    }
    
    func resetMenuFrameAfterRotate() {
        guard let superview = superview else {
            return
        }
        self.frame = CGRect(x: -3, y: 52, width: superview.frame.height, height: superview.frame.width)
        let menuView = menuTemplate()
        menuView.frame.origin = CGPoint(x: superview.frame.height - self.menuWidth - self.paddingRight, y: self.paddingTop)
        self.menuViewFrame = menuView.frame
        self.menuView?.frame = self.menuViewFrame
    }
    
    func show(in view: UIView) {
        self.removeFromSuperview()
        let menuView = menuTemplate()
        if UIDevice.current.userInterfaceIdiom == .phone {
            menuView.frame.origin = CGPoint(x: view.frame.width - menuWidth - paddingRight, y: paddingTop)
        } else {
            menuView.frame.origin = CGPoint(x: view.frame.width - menuWidth - 11.5, y: 13)
        }
        menuViewFrame = menuView.frame
        self.menuView?.frame = menuViewFrame
        view.addSubview(self)
        self.alpha = 1
        UIView.animate(withDuration: 0.15) {
            self.alpha = 1.0
        }
    }
    
    func hide(animated: Bool = true) {
        let duration: TimeInterval = animated ? 0.2: 0.0
        UIView.animate(withDuration: duration, animations: {
            let scale: CGFloat = 0.7
            self.menuView?.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.menuView?.frame.origin.x = self.menuViewFrame.origin.x + self.menuViewFrame.width * scale/2 - 12 // To keep arrow stick
            self.menuView?.frame.origin.y = self.menuViewFrame.origin.y
            self.menuView?.alpha = 0.0
        }) { _ in
            self.menuView?.alpha = 1.0
            self.menuView?.transform = .identity
            self.removeFromSuperview()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if superview != nil {
            hide()
        }
        super.touchesBegan(touches, with: event)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
