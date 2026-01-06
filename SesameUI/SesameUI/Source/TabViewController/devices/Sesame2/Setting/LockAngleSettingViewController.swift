//
//  LockAngleSettingViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/14.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

class LockAngleSettingViewController: CHBaseViewController {
    
    // MARK: Data Model
    var sesame2: CHSesame2!
    var dismissHandler: (()->Void)?
    let minimumLockPosition = -32768
    private var lockDegree: Int16 = 0
    private var unlockDegree: Int16 = 0
    private var currentDegree: Int16 = 0
    
    // MARK: UI Components
    @IBOutlet weak var topHintLabel: UILabel! {
        didSet {
            topHintLabel.text = "co.candyhouse.sesame2.PleaseConfigureAngle".localized
        }
    }
    
    @IBOutlet weak var lockView: LockView! {
        didSet {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(lockViewTapped))
            lockView.addGestureRecognizer(tapGesture)
            lockView.sesame2 = sesame2
        }
    }
    
    @IBOutlet weak var bottomHintLabel: UILabel! {
        didSet {
            bottomHintLabel.text = "co.candyhouse.sesame2.PleaseCompletelyLockUnlock".localized
        }
    }
    
    @IBOutlet weak var setLockedImageview: UIImageView! {
        didSet {
            setLockedImageview.image = UIImage.SVGImage(named: "icon_lock")
        }
    }
    
    @IBOutlet weak var setLockedButton: UIButton! {
        didSet {
            setLockedButton.setTitle("co.candyhouse.sesame2.SetLockedPosition".localized,
                                     for: .normal)
            setLockedButton.addTarget(self, action: #selector(setLockedPositionTapped), for: .touchUpInside)
        }
    }
    @IBOutlet weak var propertySelectButton: UIButton! {
        didSet {
            propertySelectButton.setTitle("co.candyhouse.sesame2.propertySelect".localized, for: .normal)
            propertySelectButton.addTarget(self, action: #selector(enterPropertyList), for: .touchUpInside)
        }
    }
    @IBOutlet weak var propertySelectContainer: UIView! {
        didSet {
            propertySelectContainer.isHidden = true
        }
    }
    
    @IBOutlet weak var setUnlockedImageView: UIImageView! {
        didSet {
            setUnlockedImageView.image = UIImage.SVGImage(named: "icon_unlock")
        }
    }
    
    @IBOutlet weak var setUnlockedButton: UIButton! {
        didSet {
            setUnlockedButton.setTitle("co.candyhouse.sesame2.SetUnlockedPosition".localized,
                                       for: .normal)
            setUnlockedButton.addTarget(self, action: #selector(setUnlockedPositionTapped), for: .touchUpInside)
        }
    }

    // MARK: - Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "co.candyhouse.sesame2.ConfigureAngles".localized
        sesame2.delegate = self
        
        if let setting = sesame2.mechSetting {
            lockDegree = setting.lockPosition
            unlockDegree = setting.unlockPosition
        }
        
        guard let status = sesame2.mechStatus else {
            return
        }
        currentDegree = status.position
        lockView.refreshUI()
        
        // 打開 comment 開啟不動產功能
//        CHMobileClient.shared.fundonsanEmploy { result in
//            if case let .success(levels) = result {
//                executeOnMainThread {
//                    // level > 0 顯示 否則隱藏
//                    self.propertySelectContainer.isHidden = levels != nil ? levels!.count == 0 : true
//                }
//            }
//        }
    }
    
    override func didBecomeActive() {
        viewWillAppear(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            dismissHandler?()
        }
    }
    
    // MARK: - User Events
    @objc func setLockedPositionTapped() {
        setLock()
    }
    
    @objc func setUnlockedPositionTapped() {
        setUnlock()
    }
    
    @objc func enterPropertyList() {
//        let propertyListViewController = FudonsanPropertyListViewController.instanceWithSesame2(sesame2, dismissHandler: dismissHandler)
//        navigationController!.pushViewController(propertyListViewController, animated: true)
    }

    
    @objc func lockViewTapped() {
            self.sesame2?.toggle { _ in }
            self.sesame2?.setAutoUnlockFlag(false)
    }


    public func setLock() {
        lockDegree = currentDegree
        if lockDegree == minimumLockPosition {
            lockDegree = 0
        }
        if unlockDegree == minimumLockPosition {
            unlockDegree = 0
        }
        L.d("angle", lockDegree, unlockDegree)
        if abs(lockDegree - unlockDegree) < 50 {
            view.makeToast(NSError.angleTooCloseError.errorDescription())
            return
        }
        ViewHelper.showLoadingInView(view: self.view)
        sesame2.configureLockPosition(lockTarget: lockDegree, unlockTarget: unlockDegree){ res in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.view)
                self.lockView.refreshUI()
            }
         }
    }
    
    // MARK: setUnlock
    public func setUnlock() {
        unlockDegree = currentDegree
        if lockDegree == minimumLockPosition {
            lockDegree = 0
        }
        if unlockDegree == minimumLockPosition {
            unlockDegree = 0
        }
        L.d("angle", lockDegree, unlockDegree)
        if abs(lockDegree - unlockDegree) < 50 {
            view.makeToast(NSError.angleTooCloseError.errorDescription())
            return
        }
        ViewHelper.showLoadingInView(view: self.view)
        sesame2.configureLockPosition(lockTarget: lockDegree, unlockTarget: unlockDegree){ res in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.view)
                self.lockView.refreshUI()
            }
        }
    }
}

// MARK: - CHSesame2Delegate
extension LockAngleSettingViewController: CHSesame2Delegate {
    public func onBleDeviceStatusChanged(device: CHDevice,
                                         status: CHDeviceStatus,shadowStatus: CHDeviceStatus?) {
        if device.deviceId == sesame2.deviceId,
            status == .receivedBle() {
            sesame2.connect() {_ in}
        }
        executeOnMainThread {
            self.lockView.refreshUI()
        }
    }
    
    public func onMechStatus(device: CHDevice) {
        guard let status = device.mechStatus else {
            return
        }
        currentDegree = status.position
        executeOnMainThread {
            self.lockView.refreshUI()
        }
    }
}

// MARK: - Designated Initializer
extension LockAngleSettingViewController {
    static func instanceWithSesame2(_ sesame2: CHSesame2, dismissHandler: (()->Void)? = nil) -> LockAngleSettingViewController {
        let lockAngleSettingViewController = LockAngleSettingViewController(nibName: "LockAngleSettingViewController", bundle: nil)
        lockAngleSettingViewController.sesame2 = sesame2
        lockAngleSettingViewController.dismissHandler = dismissHandler
        lockAngleSettingViewController.hidesBottomBarWhenPushed = true
        return lockAngleSettingViewController
    }
}
