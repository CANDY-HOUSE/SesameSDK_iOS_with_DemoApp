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
    private let sensorDetectIntervalValues: [Int16] = {
        var frequencyOrder: [Int] = []
        var intervalsByFrequency: [Int: [Int]] = [:]

        for intervalMs in stride(from: 0, through: 1000, by: 50) {
            let frequency = intervalMs == 0
                ? 0
                : Int((1000.0 / Double(intervalMs)).rounded())
            if intervalsByFrequency[frequency] == nil {
                frequencyOrder.append(frequency)
            }
            intervalsByFrequency[frequency, default: []].append(intervalMs)
        }

        return frequencyOrder.compactMap { frequency in
            guard let intervals = intervalsByFrequency[frequency] else { return nil }
            let preferredInterval = intervals.first { intervalMs in
                intervalMs != 0 && 1000 % intervalMs == 0 && 1000 / intervalMs == frequency
            } ?? intervals[0]
            return Int16(preferredInterval)
        }
    }()

    @IBOutlet weak var scrollView: UIScrollView!
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
            setMagnetButton.setTitleColor(.lockRed, for: .normal)
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(magnetLongPressed(_:)))
            setMagnetButton.addGestureRecognizer(longPress)
        }
    }

    @IBOutlet weak var switchPointContainer: UIView!
    @IBOutlet weak var switchPointSeparator: UIView!
    @IBOutlet weak var switchPointImageView: UIImageView! {
        didSet {
            switchPointImageView.image = Self.makeSwitchPointIcon()
        }
    }
    @IBOutlet weak var switchPointButton: UIButton! {
        didSet {
            switchPointButton.setTitle("co.candyhouse.sesame5.switchPoint".localized, for: .normal)
            switchPointButton.addTarget(self, action: #selector(setSwitchPointTapped), for: .touchUpInside)
        }
    }

    @IBOutlet weak var sensorDetectContainer: UIView!
    @IBOutlet weak var sensorDetectSeparator: UIView!
    private lazy var sensorDetectView: CHUIExpandableSettingView = {
        let settingView = CHUIViewGenerator.expandable { [weak self] _, _ in
            guard let self = self, self.sensorDetectView.isPickerOn else { return }
            self.view.layoutIfNeeded()
            let settingRect = self.sensorDetectView.convert(self.sensorDetectView.bounds, to: self.scrollView)
            self.scrollView.scrollRectToVisible(settingRect, animated: true)
        }
        settingView.title = "co.candyhouse.sesame5.sensorDetectFrequency".localized
        return settingView
    }()
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupFixedStatusView()
        setupSensorDetectView()
        switchPointButton.titleLabel?.font = setLockedButton.titleLabel?.font
    }

    private func setupSensorDetectView() {
        sensorDetectContainer.addSubview(sensorDetectView)
        sensorDetectView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sensorDetectView.topAnchor.constraint(equalTo: sensorDetectContainer.topAnchor),
            sensorDetectView.leadingAnchor.constraint(equalTo: sensorDetectContainer.leadingAnchor),
            sensorDetectView.trailingAnchor.constraint(equalTo: sensorDetectContainer.trailingAnchor),
            sensorDetectView.bottomAnchor.constraint(equalTo: sensorDetectContainer.bottomAnchor)
        ])
        sensorDetectView.pickerView.delegate = self
        sensorDetectView.pickerView.dataSource = self
        sensorDetectView.isPickerOn = false
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

        if let status = sesame5.mechStatus {
            currentDegree = status.position
        }
        useSlidingDoorUI = (sesame5.productModel == .sesame6ProSlidingDoor)
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
        
        guard sesame5.productModel == .sesame6Pro || sesame5.productModel == .sesame6ProSlidingDoor else {
            return
        }
        
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
        
        let advType: UInt8
        let targetModel: CHProductModel
        if sesame5.productModel == .sesame6ProSlidingDoor {
            advType = 21
            targetModel = .sesame6Pro
        } else {
            advType = 32
            targetModel = .sesame6ProSlidingDoor
        }
        
        sesame5.sendAdvProductTypeCommand(data: Data([advType])) { res in
            executeOnMainThread {
                switch res {
                case .success:
                    self.useSlidingDoorUI = (targetModel == .sesame6ProSlidingDoor)
                    self.refreshUIView()
                    self.syncProductModel(targetModel)
                case .failure(let err):
                    L.d("Sesame5LockAngle", "sendAdvProductTypeCommand fail: \(err)")
                }
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

    @objc private func setSwitchPointTapped() {
        guard sesame5.deviceStatus.loginStatus == .logined,
              let point = sesame5.mechStatus?.position else { return }
        sesame5.setLockUnlockSwitchPoint(point: point) { result in
            switch result {
            case .success:
                L.d("Sesame5LockAngle", "set switch point success: \(point)")
                executeOnMainThread {
                    self.refreshSwitchPointUI()
                }
            case .failure(let error):
                L.d("Sesame5LockAngle", "set switch point failed: \(error)")
            }
        }
    }

    private func syncProductModel(_ productModel: CHProductModel) {
        guard let updatedKey = sesame5.getKey()?.copy() as? CHDeviceKey else {
            L.d("Sesame5LockAngle", "sync product model failed: device key is missing")
            return
        }

        let deviceModel = productModel.deviceModel()
        updatedKey.deviceModel = deviceModel
        CHDeviceManager.shared.receiveCHDeviceKeys(updatedKey) { result in
            switch result {
            case .success:
                let updatedUserKey = CHUserKey.from(self.sesame5)
                CHAPIClient.shared.putCHUserKey(updatedUserKey.toData()) { result in
                    switch result {
                    case .success:
                        L.d("Sesame5LockAngle", "sync product model success: \(deviceModel)")
                    case .failure(let error):
                        L.d("Sesame5LockAngle", "sync product model failed: \(error)")
                    }
                }
            case .failure(let error):
                L.d("Sesame5LockAngle", "save product model locally failed: \(error)")
            }
        }
    }
    
    func refreshUIView() {
        refreshAngleUI()
        refreshSwitchPointUI()
        refreshSensorDetectIntervalUI()
    }

    private func refreshAngleUI() {
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

    private func refreshSwitchPointUI() {
        let isSupported = sesame5.hasLockUnlockSwitchPointSetting
        switchPointContainer.isHidden = !isSupported
        switchPointSeparator.isHidden = !isSupported
        switchPointButton.isEnabled = sesame5.deviceStatus.loginStatus == .logined &&
            sesame5.mechStatus != nil

        if isSupported {
            lockView.setSwitchPoint(sesame5.lockUnlockSwitchPoint)
            slidingDoorView.setSwitchPoint(sesame5.lockUnlockSwitchPoint)
        } else {
            lockView.clearSwitchPoint()
            slidingDoorView.clearSwitchPoint()
        }
    }

    private func refreshSensorDetectIntervalUI() {
        let intervalMs = sesame5.sensorDetectIntervalMs
        let isSupported = intervalMs != CHDeviceUnsetSensorDetectInterval
        let isLoggedIn = sesame5.deviceStatus.loginStatus == .logined
        sensorDetectContainer.isHidden = !isSupported
        sensorDetectSeparator.isHidden = !isSupported
        sensorDetectView.isUserInteractionEnabled = isSupported && isLoggedIn

        guard isSupported else {
            sensorDetectView.isPickerOn = false
            return
        }
        if !isLoggedIn {
            sensorDetectView.isPickerOn = false
        }

        sensorDetectView.value = sensorDetectFrequencyText(intervalMs)
        let selectedRow = sensorDetectIntervalValues.enumerated().min {
            abs(Int($0.element) - Int(intervalMs)) < abs(Int($1.element) - Int(intervalMs))
        }?.offset ?? 0
        sensorDetectView.pickerView.selectRow(selectedRow, inComponent: 0, animated: false)
    }

    private func sensorDetectFrequencyText(_ intervalMs: Int16) -> String {
        guard intervalMs != 0 else {
            return "co.candyhouse.sesame5.stopDetection".localized
        }
        let frequency = Int((1000.0 / Double(intervalMs)).rounded())
        return String(
            format: "co.candyhouse.sesame5.timesPerSecond".localized,
            arguments: [frequency]
        )
    }

    private func sensorDetectIntervalSecondsText(_ intervalMs: Int16) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: Double(intervalMs) / 1000.0)) ?? "0"
    }

    private static func makeSwitchPointIcon() -> UIImage {
        let size = CGSize(width: 25, height: 35)
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            let context = rendererContext.cgContext
            context.setStrokeColor(UIColor.placeholderText.cgColor)
            context.setLineWidth(2)
            context.setLineCap(.round)
            context.setLineDash(phase: 0, lengths: [4, 3])
            context.move(to: CGPoint(x: size.width / 2, y: 2))
            context.addLine(to: CGPoint(x: size.width / 2, y: size.height - 2))
            context.strokePath()
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
            self.refreshAngleUI()
            self.refreshSwitchPointUI()
        }
    }

    public func onSensorDetectIntervalReceive(device: CHSesame5, intervalMs: Int16) {
        guard device.deviceId == sesame5.deviceId else { return }
        executeOnMainThread {
            self.refreshSensorDetectIntervalUI()
        }
    }

    public func onLockUnlockSwitchPointReceive(device: CHSesame5, point: Int16) {
        guard device.deviceId == sesame5.deviceId else { return }
        executeOnMainThread {
            self.refreshSwitchPointUI()
        }
    }
}

extension Sesame5LockAngleViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        sensorDetectIntervalValues.count
    }

    func pickerView(
        _ pickerView: UIPickerView,
        viewForRow row: Int,
        forComponent component: Int,
        reusing view: UIView?
    ) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.text = sensorDetectFrequencyText(sensorDetectIntervalValues[row])
        return label
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let intervalMs = sensorDetectIntervalValues[row]
        sesame5.setSensorDetectInterval(intervalMs: intervalMs) { result in
            switch result {
            case .success:
                L.d(
                    "Sesame5LockAngle",
                    "set sensor detect interval success: \(self.sensorDetectIntervalSecondsText(intervalMs)) seconds \(intervalMs)"
                )
                executeOnMainThread {
                    self.refreshSensorDetectIntervalUI()
                    self.sensorDetectView.isPickerOn = false
                }
            case .failure(let error):
                L.d("Sesame5LockAngle", "set sensor detect interval failed: \(error)")
                executeOnMainThread {
                    self.refreshSensorDetectIntervalUI()
                }
            }
        }
    }
}
