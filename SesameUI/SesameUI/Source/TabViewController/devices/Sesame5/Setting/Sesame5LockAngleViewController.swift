//
//  Sesame5LockAngleVC.swift
//  SesameUI
//
//  Created by tse on 2023/3/8.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

class Sesame5LockAngleViewController: CHBaseViewController {

    private let statusViewHeight: CGFloat = 64
    private var baseScrollViewTopConstant: CGFloat = 0

    @IBOutlet weak var scrollViewTopConstraint: NSLayoutConstraint!

    private lazy var statusView: CHUIPlainSettingView = {
        let view = CHUIViewGenerator.plain()
        view.backgroundColor = .lockRed
        view.title = ""
        view.setColor(.white)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var sesame5: CHSesame5!
    var dismissHandler: (()->Void)?
    private var lockDegree: Int16 = 0
    private var unlockDegree: Int16 = 0
    private var currentDegree: Int16 = 0
    
    private var useSlidingDoorUI: Bool = false
    private var didTrigger2s: Bool = false

    private lazy var slidingDoorView: SlidingDoorAngleView = {
        let v = SlidingDoorAngleView(frame: .zero)
        v.isHidden = true
        v.isUserInteractionEnabled = true
        v.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(lockViewTapped)))
        return v
    }()

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
            
            if slidingDoorView.superview == nil, let parent = lockView.superview {
                parent.addSubview(slidingDoorView)
                slidingDoorView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    slidingDoorView.centerXAnchor.constraint(equalTo: lockView.centerXAnchor),
                    slidingDoorView.centerYAnchor.constraint(equalTo: lockView.centerYAnchor),
                    slidingDoorView.widthAnchor.constraint(equalTo: lockView.widthAnchor, constant: 70),
                    slidingDoorView.heightAnchor.constraint(equalTo: lockView.heightAnchor, constant: 80)
                ])
            }
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
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(magnetLongPressed(_:)))
            longPress.minimumPressDuration = 2.0
            setMagnetButton.addGestureRecognizer(longPress)
        }
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupFixedStatusView()
    }
    
    private func setupFixedStatusView() {
        baseScrollViewTopConstant = scrollViewTopConstraint.constant

        view.addSubview(statusView)

        let heightConstraint = statusView.heightAnchor.constraint(equalToConstant: statusViewHeight)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true

        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            statusView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        view.bringSubviewToFront(statusView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "co.candyhouse.sesame2.ConfigureAngles".localized
        sesame5.delegate = self
        
        showStatusViewIfNeeded()
        
        if let setting = sesame5.mechSetting {
            lockDegree = setting.lockPosition
            unlockDegree = setting.unlockPosition
        }

        guard let status = sesame5.mechStatus else {
            return
        }
        currentDegree = status.position
        useSlidingDoorUI = (sesame5.productModel == .sesame6ProSLiDingDoor)
        self.refreshUIView()
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
    @objc private func magnetLongPressed(_ g: UILongPressGestureRecognizer) {
        guard g.state == .began else { return }
        didTrigger2s = true
        
        guard sesame5.productModel == .sesame6Pro || sesame5.productModel == .sesame6ProSLiDingDoor else {
            return
        }
        
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        
        let advType: UInt8
        let targetUseSliding: Bool
        if sesame5.productModel == .sesame6ProSLiDingDoor {
            advType = 21
            targetUseSliding = false
        } else {
            advType = 32
            targetUseSliding = true
        }
        
        sesame5.sendAdvProductTypeCommand(data: Data([advType])) { res in
            executeOnMainThread {
                switch res {
                case .success:
                    self.useSlidingDoorUI = targetUseSliding
                    self.refreshUIView()
                case .failure(let err):
                    L.d("Sesame5LockAngle", "sendAdvProductTypeCommand fail: \(err)")
                }
            }
        }
    }
    @objc func setMAgnetPositionTapped() {
        if didTrigger2s {
            didTrigger2s = false
            return
        }
        ViewHelper.showLoadingInView(view: self.view)
        self.sesame5?.magnet { _ in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.view)
                self.refreshUIView()
            }
        }
    }
    
    func refreshUIView() {
        if useSlidingDoorUI {
            lockView.isHidden = true
            slidingDoorView.isHidden = false
            slidingDoorView.update(
                pos: sesame5.mechStatus?.position ?? 0,
                lock: sesame5.mechSetting?.lockPosition ?? 0,
                unlock: sesame5.mechSetting?.unlockPosition ?? 0
            )
        } else {
            slidingDoorView.isHidden = true
            lockView.isHidden = false
            lockView.refreshUI()
        }
        
        if let mechStatus = sesame5.mechStatus {
            topAngleLabel.text = String(format: "%d°", mechStatus.position)
        }
    }
    
    @discardableResult
    func showStatusViewIfNeeded() -> Bool {
        let shouldShow: Bool

        if CHBluetoothCenter.shared.scanning.bleStatus == .closed {
            statusView.title = "co.candyhouse.sesame2.bluetoothPoweredOff".localized
            shouldShow = true
        } else if sesame5.deviceStatus.loginStatus == .unlogined {
            statusView.title = sesame5.localizedDescription()
            shouldShow = true
        } else {
            shouldShow = false
        }

        statusView.isHidden = !shouldShow
        scrollViewTopConstraint.constant = baseScrollViewTopConstant + (shouldShow ? statusViewHeight : 0)

        view.bringSubviewToFront(statusView)
        view.layoutIfNeeded()

        return shouldShow
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
            self.showStatusViewIfNeeded()
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
