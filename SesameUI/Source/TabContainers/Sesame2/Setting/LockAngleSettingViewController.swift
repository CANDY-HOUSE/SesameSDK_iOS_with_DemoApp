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
    enum LockAngleError: Error {
        case tooClose
    }
    
    // MARK: Data Model
    var sesame2: CHSesame2!
    
    
    // MARK: Properties
    let minimumLockPosition = -32768
    private var lockDegree: Int16 = 0
    private var unlockDegree: Int16 = 0
    private var currentDegree: Int16 = 0
    
    // MARK: UI Components
    @IBOutlet weak var topHintLabel: UILabel! {
        didSet {
            topHintLabel.text = "co.candyhouse.sesame-sdk-test-app.PleaseConfigureAngle".localized
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
            bottomHintLabel.text = "co.candyhouse.sesame-sdk-test-app.PleaseCompletelyLockUnlock".localized
        }
    }
    
    @IBOutlet weak var setLockedImageview: UIImageView! {
        didSet {
            setLockedImageview.image = UIImage.SVGImage(named: "icon_lock")
        }
    }
    
    @IBOutlet weak var setLockedButton: UIButton! {
        didSet {
            setLockedButton.setTitle("co.candyhouse.sesame-sdk-test-app.SetLockedPosition".localized,
                                     for: .normal)
            setLockedButton.addTarget(self, action: #selector(setLockedPositionTapped), for: .touchUpInside)
        }
    }
    
    @IBOutlet weak var setUnlockedImageView: UIImageView! {
        didSet {
            setUnlockedImageView.image = UIImage.SVGImage(named: "icon_unlock")
        }
    }
    
    @IBOutlet weak var setUnlockedButton: UIButton! {
        didSet {
            setUnlockedButton.setTitle("co.candyhouse.sesame-sdk-test-app.SetUnlockedPosition".localized,
                                       for: .normal)
            setUnlockedButton.addTarget(self, action: #selector(setUnlockedPositionTapped), for: .touchUpInside)
        }
    }

    // MARK: - Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "co.candyhouse.sesame-sdk-test-app.ConfigureAngles".localized
        sesame2.delegate = self
        
        if let setting = sesame2.mechSetting {
            lockDegree = setting.lockPosition
            unlockDegree = setting.unlockPosition
        } else {
            let error = NSError(domain: "co.candyhouse.sesame-sdk-test-app", code: 0, userInfo: ["message": "Get sesame setting failed."])
            view.makeToast(error.errorDescription())
        }
        
        guard let status = sesame2.mechStatus else {
            return
        }
        currentDegree = status.position
        lockView.refreshUI()
    }
    
    // MARK: - User Events
    @objc func setLockedPositionTapped() {
        setLock()
    }
    
    @objc func setUnlockedPositionTapped() {
        setUnlock()
    }
    
    @objc func lockViewTapped() {
        sesame2.toggle { _ in
            
        }
    }
    
    // MARK: - Methods
    
    
    
    // MARK: setLock
    public func setLock() {
        lockDegree = currentDegree
        if lockDegree == minimumLockPosition {
            lockDegree = 0
        }
        if unlockDegree == minimumLockPosition {
            unlockDegree = 0
        }
        if abs(lockDegree - unlockDegree) < 50 {
            view.makeToast(LockAngleError.tooClose.errorDescription())
            return
        }
        sesame2.configureLockPosition(lockTarget: lockDegree, unlockTarget: unlockDegree){ res in

         }
        lockView.refreshUI()
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

        if abs(lockDegree - unlockDegree) < 50 {
            view.makeToast(LockAngleError.tooClose.errorDescription())
            return
        }
        sesame2.configureLockPosition(lockTarget: lockDegree, unlockTarget: unlockDegree){ res in
            
        }
        lockView.refreshUI()
    }
}

// MARK: - CHSesame2Delegate
extension LockAngleSettingViewController: CHSesame2Delegate {
    public func onBleDeviceStatusChanged(device: CHSesame2,
                                         status: CHSesame2Status,shadowStatus: CHSesame2ShadowStatus?) {
        if device.deviceId == sesame2.deviceId,
            status == .receivedBle {
            sesame2.connect(){_ in}
        }
        executeOnMainThread {
            self.lockView.refreshUI()
        }
    }
    
    public func onMechStatusChanged(device: CHSesame2,
                                    status: CHSesame2MechStatus,
                                    intention: CHSesame2Intention) {
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
    static func instanceWithSesame2(_ sesame2: CHSesame2) -> LockAngleSettingViewController {
        let lockAngleSettingViewController = LockAngleSettingViewController(nibName: "LockAngleSettingViewController", bundle: nil)
        lockAngleSettingViewController.sesame2 = sesame2
        return lockAngleSettingViewController
    }
}
