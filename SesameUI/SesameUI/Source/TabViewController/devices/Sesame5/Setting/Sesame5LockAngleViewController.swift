//
//  Sesame5LockAngleVC.swift
//  SesameUI
//
//  Created by tse on 2023/3/8.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

// todo 校正磁铁
class Sesame5LockAngleViewController: CHBaseViewController {

    var sesame5: CHSesame5!
    var dismissHandler: (()->Void)?
    private var lockDegree: Int16 = 0
    private var unlockDegree: Int16 = 0
    private var currentDegree: Int16 = 0

    @IBOutlet weak var setUnlockImageView: UIImageView!{
        didSet {
            setUnlockImageView.image = UIImage.SVGImage(named: "icon_unlock")
        }
    }

    @IBOutlet weak var setLockedImageview: UIImageView! {
        didSet {
            setLockedImageview.image = UIImage.SVGImage(named: "icon_lock")
        }
    }
    
    @IBOutlet weak var topAngleLabel: UILabel!

    
    @IBOutlet weak var topHintLabel: UILabel! {
        didSet {
            topHintLabel.text = "co.candyhouse.sesame2.PleaseConfigureAngle".localized
        }
    }
    @IBOutlet weak var bottomHintLabel: UILabel! {
        didSet {
            bottomHintLabel.text = "co.candyhouse.sesame2.PleaseCompletelyLockUnlock".localized
        }
    }
    @IBOutlet weak var lockView: LockViewSS5! {
        didSet {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(lockViewTapped))
            lockView.addGestureRecognizer(tapGesture)
            lockView.sesame5 = sesame5
        }
    }
    @IBOutlet weak var setLockedButton: UIButton! {
        didSet {
            setLockedButton.setTitle("co.candyhouse.sesame2.SetLockedPosition".localized,
                                     for: .normal)
            setLockedButton.addTarget(self, action: #selector(setLockedPositionTapped), for: .touchUpInside)
        }
    }
    @IBOutlet weak var setUnlockedButton: UIButton! {
        didSet {
            setUnlockedButton.setTitle("co.candyhouse.sesame2.SetUnlockedPosition".localized,
                                       for: .normal)
            setUnlockedButton.addTarget(self, action: #selector(setUnlockedPositionTapped), for: .touchUpInside)
        }
    }
    @IBOutlet weak var setMagnetButton: UIButton! {
        didSet {
            setMagnetButton.addTarget(self, action: #selector(setMAgnetPositionTapped), for: .touchUpInside)
            setMagnetButton.setTitle("co.candyhouse.sesame2.SetMagnetPosition".localized,
                                       for: .normal)
        }
    }
    
    // MARK: - Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "co.candyhouse.sesame2.ConfigureAngles".localized
        sesame5.delegate = self
        if let setting = sesame5.mechSetting {
            lockDegree = setting.lockPosition
            unlockDegree = setting.unlockPosition
        }

        guard let status = sesame5.mechStatus else {
            return
        }
        currentDegree = status.position
        self.refreshUIView()
//        L.d("[UI][ss5][refreshUI]",sesame5.mechStatus?.position)
    }

    @objc func lockViewTapped() {
        self.sesame5?.toggle(historytag: self.sesame5?.hisTag) { _ in }
    }
    // MARK: - User Events
    @objc func setLockedPositionTapped() {
        lockDegree = currentDegree
        L.d("angle", lockDegree, unlockDegree)
        ViewHelper.showLoadingInView(view: self.view)
        sesame5.configureLockPosition(lockTarget: lockDegree, unlockTarget: unlockDegree){ res in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.view)
                self.refreshUIView()
            }
        }
    }
    @objc func setUnlockedPositionTapped() {
        unlockDegree = currentDegree
        L.d("angle", lockDegree, unlockDegree)
        ViewHelper.showLoadingInView(view: self.view)
        sesame5.configureLockPosition(lockTarget: lockDegree, unlockTarget: unlockDegree){ res in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.view)
                self.refreshUIView()
            }
        }
    }
    @objc func setMAgnetPositionTapped() {
        ViewHelper.showLoadingInView(view: self.view)
        self.sesame5?.magnet { _ in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.view)
                self.refreshUIView()
            }
        }
    }
    
    func refreshUIView() {
        self.lockView.refreshUI()        
        if let mechStatus = sesame5.mechStatus {
            self.topAngleLabel.text =  String(format: "%d°", mechStatus.position)
        }
    }

}



// MARK: - Designated Initializer
extension Sesame5LockAngleViewController {
    static func instance(_ sesame5: CHSesame5, dismissHandler: (()->Void)? = nil) -> Sesame5LockAngleViewController {
        let vc = Sesame5LockAngleViewController(nibName: "Sesame5LockAngle", bundle: nil)
        vc.sesame5 = sesame5
        vc.dismissHandler = dismissHandler
        vc.hidesBottomBarWhenPushed = true
        return vc
    }
}


// MARK: - CHSesame2Delegate
extension Sesame5LockAngleViewController: CHSesame5Delegate {
    public func onBleDeviceStatusChanged(device: CHDevice,
                                         status: CHDeviceStatus,shadowStatus: CHDeviceStatus?) {
        if device.deviceId == sesame5.deviceId,
            status == .receivedBle() {
            sesame5.connect() {_ in}
        }
        executeOnMainThread {
            self.refreshUIView()
        }
    }

    public func onMechStatus(device: CHDevice) {
        guard let status = device.mechStatus else {
            return
        }
        
        currentDegree = status.position
        executeOnMainThread {
            self.refreshUIView()
        }
    }
}
