// Sesame5SettingViewController.swift

import UIKit
import SesameSDK
import NordicDFU
import CoreBluetooth
import IntentsUI

class Sesame5SettingViewController: CHBaseViewController, CHDeviceStatusDelegate {

    var sesame5: CHSesame5!
    var statusView: CHUIPlainSettingView!
    let contentStackView = UIStackView(frame: .zero)
    var changeNameView: CHUIPlainSettingView!
    var dfuView: CHUIPlainSettingView!
    var autoLockView: CHUITogglePickerSettingView!
    var opsLockView: CHUIExpandableSettingView!
    var autoUnLockView: CHUIArrowSettingView!
    var notificationToggleView: CHUIToggleSettingView?
    var voiceShortcutButton: CHUISettingButtonView?
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var isReset: Bool = false

    // MARK: - Values for UI
    var versionStr: String? { //fw version in device
        didSet {
            executeOnMainThread {
                self.dfuView.value = self.versionStr ?? ""
            }
        }
    }
    var autoLockInt: Int16? {
        didSet {
            executeOnMainThread {
                self.autoLockView?.switchView.isEnabled = (self.sesame5.deviceStatus.loginStatus == .logined)
                if let autoLockInt = self.autoLockInt{
                    let  autoLock = Int(autoLockInt)
                    self.autoLockView?.switchView.isOn = (autoLock ) > 0
                    let secondPickerSelectedRow  = self.secondSettingValue.firstIndex(of: autoLock )  ?? 0
                    if(autoLock == 0){
                        self.autoLockView?.value = ""
                    }else{
                        let autoLockValueLabelText = String(format: "co.candyhouse.sesame2.secAfter".localized, arguments: [self.formatedTimeFromSec(self.secondSettingValue[secondPickerSelectedRow])])
                        self.autoLockView?.value = autoLockValueLabelText
                    }
                    self.autoLockView?.pickerView.selectRow(secondPickerSelectedRow, inComponent: 0, animated: false)
                }else{
                    self.autoLockView?.switchView.isOn = false
                }
            }
        }
    }
    var opsLockUInt: UInt16?{
        didSet{
            executeOnMainThread {
                let opsLockInt = Int(self.opsLockUInt ?? 65535)
                let opsSecs = self.formatedTimeFromSec(opsLockInt)
                if(opsLockInt == 65535 || opsLockInt == 0){ 
                    self.opsLockView?.value = opsSecs
                }else{
                    let opsText = String(format: "co.candyhouse.sesame2.secAfter".localized, arguments: [opsSecs])
                    self.opsLockView?.value = opsText
                }
                self.opsLockView.pickerView.selectRow(self.opsSecondSettingValue.firstIndex(of: opsLockInt) ?? 0, inComponent: 0, animated: false)
            }
        }
    }
    var dismissHandler: ((_ isReset: Bool)->Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        let scrollView = UIScrollView(frame: .zero)
        view.backgroundColor = .sesame2Gray
        scrollView.addSubview(contentStackView)
        view.addSubview(scrollView)

        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 0
        contentStackView.distribution = .fill

        UIView.autoLayoutStackView(contentStackView, inScrollView: scrollView)
        arrangeSubviews()
        DFUCenter.shared.confirmDFUDeletegate(self, forDevice: sesame5)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sesame5.delegate = self

        autoLockInt = sesame5.mechSetting?.autoLockSecond
        opsLockUInt = sesame5.opsSetting?.opsLockSecond

        if sesame5.deviceStatus == .receivedBle() {
            sesame5.connect() { _ in }
        }
        getVersionTag()
        autoUnLockView.value = self.sesame5.autoUnlockStatus() == true ? "co.candyhouse.sesame2.on".localized : "co.candyhouse.sesame2.off".localized
        showStatusViewIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            DFUCenter.shared.removeDFUDelegateForDevice(sesame5)
            dismissHandler?(isReset)
        }
    }

    func arrangeSubviews() {
        
        // MARK: top status
        statusView = CHUIViewGenerator.plain()
        statusView.backgroundColor = .lockRed
        statusView.title = ""
        statusView.setColor(.white)
        contentStackView.addArrangedSubview(statusView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        
        // MARK: Change name
        changeNameView = CHUIViewGenerator.plain { [unowned self] _,_ in
            self.changeName()
        }
        changeNameView.title = "co.candyhouse.sesame2.EditName".localized
        changeNameView.value = sesame5.deviceName
        contentStackView.addArrangedSubview(changeNameView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))


        // MARK: Device model
        let modelView = CHUIViewGenerator.plain()
        modelView.title = "co.candyhouse.sesame2.model".localized
        modelView.value = sesame5.productModel.deviceModelName()
        contentStackView.addArrangedSubview(modelView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))

        
        // MARK: Angle setting
        let angleSettingView = CHUIViewGenerator.arrow { [unowned self] _,_ in
            navigationController?.pushViewController(Sesame5LockAngleViewController.instance(sesame5),animated: true)
        }
        angleSettingView.title = "co.candyhouse.sesame2.ConfigureAngles".localized
        contentStackView.addArrangedSubview(angleSettingView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))

        
        // MARK: Enable Notification
        notificationToggleView = CHUIViewGenerator.toggle { [unowned self] sender,_ in
            if let toggle = sender as? UISwitch {
                self.enableNotificationToggled(sender: toggle)
            }
        }
        notificationToggleView!.title = "co.candyhouse.sesame2.enableNotification".localized
        contentStackView.addArrangedSubview(notificationToggleView!)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        
        // MARK: OP sensor lock
        opsLockView = CHUIViewGenerator.expandable(){ [unowned self] sender,_ in }
        opsLockView.title = "co.candyhouse.sesame2.OpSensorOn".localized
        opsLockView.pickerView.delegate = self
        opsLockView.pickerView.dataSource = self
        opsLockView.pickerView.tag = 2
        opsLockView.fold()
        contentStackView.addArrangedSubview(opsLockView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))

        
        // MARK: AutoLock
        autoLockView = CHUIViewGenerator.togglePicker() { [unowned self] sender,_ in
            if(autoLockView.switchView.isOn == false){
                self.sesame5.enableAutolock(delay: 0) { result  in
                    switch result {
                    case .success(_):
                        self.autoLockInt = 0
                    case .failure(let error):
                        L.d(error.errorDescription())
                    }
                }
            }
        }
        autoLockView.title = "co.candyhouse.sesame2.AutoLock".localized
        autoLockView.pickerView.delegate = self
        autoLockView.pickerView.dataSource = self
        autoLockView.pickerView.tag = 1
        autoLockView.fold()
        contentStackView.addArrangedSubview(autoLockView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        

        // MARK: SiriButton
        if #available(iOS 12.0, *) {
            voiceShortcutButton = CHUIViewGenerator.button() { [unowned self] sender,_ in

                let chooseVoiceShortcutViewController = UIAlertController(title: nil, message: "co.candyhouse.sesame2.chooseVoiceShortcut".localized, preferredStyle: .actionSheet)

                let toggleShortcut = UIAlertAction(title: "co.candyhouse.sesame2.toggle".localized, style: .default) { _ in
                    let intent = ToggleSesameIntent()
                    intent.suggestedInvocationPhrase = "co.candyhouse.sesame2.suggestedPhrase".localized
                    intent.name = self.sesame5.deviceName
                    if let shortcut = INShortcut(intent: intent) {
                        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
                            executeOnMainThread {
                                if let voiceShortcutIds = shortcuts?.map({ $0.identifier }),
                                   let voiceShortcutId = self.sesame5.getVoiceToggleId(),
                                   voiceShortcutIds.contains(voiceShortcutId) {
                                    let voiceShortcut = shortcuts!.filter({ $0.identifier == voiceShortcutId }).first!
                                    let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: voiceShortcut)
                                    viewController.modalPresentationStyle = .formSheet
                                    viewController.delegate = self
                                    self.present(viewController, animated: true, completion: nil)
                                } else {
                                    let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
                                    viewController.modalPresentationStyle = .formSheet
                                    viewController.delegate = self
                                    self.present(viewController, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                }

                let lockShortcut = UIAlertAction(title: "co.candyhouse.sesame2.lock".localized, style: .default) { _ in
                    let intent = LockSesameIntent()
                    intent.suggestedInvocationPhrase = "co.candyhouse.sesame2.suggestedPhrase".localized
                    intent.name = self.sesame5.deviceName
                    if let shortcut = INShortcut(intent: intent) {
                        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
                            executeOnMainThread {
                                if let voiceShortcutIds = shortcuts?.map({ $0.identifier }),
                                   let voiceShortcutId = self.sesame5.getVoiceLockId(),
                                   voiceShortcutIds.contains(voiceShortcutId) {
                                    let voiceShortcut = shortcuts!.filter({ $0.identifier == voiceShortcutId }).first!
                                    let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: voiceShortcut)
                                    viewController.modalPresentationStyle = .formSheet
                                    viewController.delegate = self
                                    self.present(viewController, animated: true, completion: nil)
                                } else {
                                    let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
                                    viewController.modalPresentationStyle = .formSheet
                                    viewController.delegate = self
                                    self.present(viewController, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                }

                let unlockShortcut = UIAlertAction(title: "co.candyhouse.sesame2.unlock".localized, style: .default) { _ in
                    let intent = UnlockSesameIntent()
                    intent.suggestedInvocationPhrase = "co.candyhouse.sesame2.suggestedPhrase".localized
                    intent.name = self.sesame5.deviceName
                    if let shortcut = INShortcut(intent: intent) {
                        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
                            executeOnMainThread {
                                if let voiceShortcutIds = shortcuts?.map({ $0.identifier }),
                                   let voiceShortcutId = self.sesame5.getVoiceUnlockId(),
                                   voiceShortcutIds.contains(voiceShortcutId) {
                                    let voiceShortcut = shortcuts!.filter({ $0.identifier == voiceShortcutId }).first!
                                    let viewController = INUIEditVoiceShortcutViewController(voiceShortcut: voiceShortcut)
                                    viewController.modalPresentationStyle = .formSheet
                                    viewController.delegate = self
                                    self.present(viewController, animated: true, completion: nil)
                                } else {
                                    let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
                                    viewController.modalPresentationStyle = .formSheet
                                    viewController.delegate = self
                                    self.present(viewController, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                }
                chooseVoiceShortcutViewController.addAction(toggleShortcut)
                chooseVoiceShortcutViewController.addAction(lockShortcut)
                chooseVoiceShortcutViewController.addAction(unlockShortcut)
                chooseVoiceShortcutViewController.addAction(.init(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil))
                chooseVoiceShortcutViewController.popoverPresentationController?.sourceView = voiceShortcutButton
                present(chooseVoiceShortcutViewController, animated: true, completion: nil)
            }
            voiceShortcutButton!.title = "co.candyhouse.sesame2.voiceShortcut".localized
            contentStackView.addArrangedSubview(voiceShortcutButton!)
            contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        }
        
        
        // MARK: OTA
        dfuView = CHUIViewGenerator.plain { [unowned self] sender,_ in
            let chooseDFUModeAlertController = UIAlertController(title: "",
                                                                 message: "co.candyhouse.sesame2.SesameOSUpdate".localized,
                                                                 preferredStyle: .actionSheet)
            let confirmAction = UIAlertAction(title: DFUHelper.getDfuFileName(self.sesame5),
                                              style: .default) { _ in
                
                self.dfuSesame(self.sesame5)
            }
            chooseDFUModeAlertController.addAction(confirmAction)
            chooseDFUModeAlertController.addAction(UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized,
                                                                 style: .cancel,
                                                                 handler: nil))
            if let popover = chooseDFUModeAlertController.popoverPresentationController {
                popover.sourceView = self.dfuView
                popover.sourceRect = self.dfuView.bounds
            }
            self.present(chooseDFUModeAlertController, animated: true, completion: nil)
        }
        dfuView.title = "co.candyhouse.sesame2.SesameOSUpdate".localized
        contentStackView.addArrangedSubview(dfuView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
        
        
        // MARK: UUID
        let uuidView = CHUIViewGenerator.plain ()
        uuidView.title = "UUID".localized
        uuidView.value = sesame5.deviceId.uuidString
        contentStackView.addArrangedSubview(uuidView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        
        // MARK: Drop key
        let dropKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.dropKey(sender: sender as! UIButton)
        }
        dropKeyView.title = "co.candyhouse.sesame2.TrashTheKey".localized
        contentStackView.addArrangedSubview(dropKeyView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))
        
        
        // MARK: Drop Key Hint
        let titleLabelContainer = UIView(frame: .zero)
        let titleLabel = UILabel(frame: .zero)
        titleLabel.text = String(format: "co.candyhouse.sesame2.dropKeyDesc".localized, arguments: ["co.candyhouse.sesame2.Sesame".localized, "co.candyhouse.sesame2.Sesame".localized, "co.candyhouse.sesame2.Sesame".localized])
        titleLabel.textColor = UIColor.placeHolderColor
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabelContainer.addSubview(titleLabel)
        titleLabel.autoPinLeading(constant: 10)
        titleLabel.autoPinTrailing(constant: -10)
        titleLabel.autoPinTop()
        titleLabel.autoPinBottom()
        contentStackView.addArrangedSubview(titleLabelContainer)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thick))

        
#if DEBUG
        // MARK: Reset Sesame
        let resetKeyView = CHUICallToActionView(textColor: .lockRed) { [unowned self] sender,_ in
            self.confirmReset(sender as! UIButton)
        }
        resetKeyView.title = "co.candyhouse.sesame2.ResetSesame".localized
        contentStackView.addArrangedSubview(resetKeyView)
#endif

        let spacerView = UIView()
        contentStackView.addArrangedSubview(spacerView)
        NSLayoutConstraint.activate([
            spacerView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])

        // MARK: Auto Unlock
        autoUnLockView = CHUIViewGenerator.arrow() { [unowned self] sender,_ in
            self.navigationController?.pushViewController(GPSMapViewController.instanceWithSesame2(sesame5), animated: true)
        }
        autoUnLockView.title = "co.candyhouse.sesame2.AutoUnlock".localized

        contentStackView.addArrangedSubview(autoUnLockView)
        contentStackView.addArrangedSubview(CHUISeperatorView(style: .thin))
    }

    // MARK: OTA
    func dfuSesame(_ sesame: CHDevice) {
        DFUCenter.shared.dfuDevice(sesame, delegate: self)
        self.versionStr = nil
    }
    func confirmReset(_ sender: UIButton) {
        let unregister = UIAlertAction(title: "co.candyhouse.sesame2.ResetSesame".localized,
                                       style: .destructive) { _ in
            self.resetSesame5()
        }
        let close = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized,
                                  style: .cancel) { (action) in

        }
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(unregister)
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = sender
        present(alertController, animated: true, completion: nil)
    }
    func resetSesame5() {
        ViewHelper.showLoadingInView(view: view)
        Sesame2Store.shared.deletePropertyFor(self.sesame5)
        self.sesame5.unregisterNotification()
        self.sesame5.reset { resetResult in
            executeOnMainThread {
                ViewHelper.hideLoadingView(view: self.view)
                self.isReset = true
                self.navigationController?.popToRootViewController(animated: false)
            }
        }
    }
    
    // MARK: Trash Key
    func dropKey(sender: UIButton) {
        let trashKey = UIAlertAction(title: "co.candyhouse.sesame2.TrashTheKey".localized,
                                     style: .destructive) { (action) in
            ViewHelper.showLoadingInView(view: self.view)
                Sesame2Store.shared.deletePropertyFor(self.sesame5)
                self.sesame5.unregisterNotification()
                self.sesame5.dropKey() { _ in
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
                        self.isReset = true
                        self.navigationController?.popToRootViewController(animated: false)
                    }
                }
            }
        let close = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized, style: .cancel, handler: nil)
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(trashKey)
        alertController.addAction(close)
        alertController.popoverPresentationController?.sourceView = sender
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Version Tag
    private func getVersionTag() {
        sesame5.getVersionTag { result in
            switch result {
            case .success(let status):
                let fileName = DFUHelper.getDfuFileName(self.sesame5!).split(separator: "_")
                let latestVersion = String(fileName.last!).components(separatedBy: ".zip").first
                let isnewest = status.data.contains(latestVersion!)
//                L.d("getVersionTag",status.data,latestVersion,isnewest)
                self.versionStr = "\(status.data)\(isnewest ? "\("co.candyhouse.sesame2.latest".localized)" : "")"
                executeOnMainThread {
                    self.dfuView.exclamation.isHidden = isnewest
                }
            case .failure(let error):
                L.d(error.errorDescription())
            }
        }
    }
    func changeName() {
        ChangeValueDialog.show(sesame5.deviceName, title: "co.candyhouse.sesame2.EditName".localized) { name in
            self.sesame5.setDeviceName(name)
            self.changeNameView.value = name
            if let navController = GeneralTabViewController.getTabViewControllersBy(0) as? UINavigationController, let listViewController = navController.viewControllers.first as? SesameDeviceListViewController {
                listViewController.reloadTableView()
            }
            WatchKitFileTransfer.shared.transferKeysToWatch()
        }
    }
    
    // MARK: enableNotificationToggle
    func enableNotificationToggled(sender: UISwitch) {
        ViewHelper.showLoadingInView(view: self.notificationToggleView)
        if let deviceToken = UserDefaults.standard.string(forKey: "devicePushToken") {
            if sender.isOn == true {
                sesame5.enableNotification(token: deviceToken, name: "Sesame2") { result in
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.notificationToggleView)
                    }
                }
            } else {
                sesame5.disableNotification(token: deviceToken, name: "Sesame2") { result in
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.notificationToggleView)
                    }
                }
            }
        }
    }


    @discardableResult
    func showStatusViewIfNeeded() -> Bool {
        if CHBluetoothCenter.shared.scanning == .bleClose() {
            statusView.title = "co.candyhouse.sesame2.bluetoothPoweredOff".localized
            statusView.isHidden = false
        } else if sesame5.deviceStatus.loginStatus == .unlogined {
            statusView.title = sesame5.localizedDescription()
            statusView.isHidden = false
        } else {
            statusView.isHidden = true
        }
        return !statusView.isHidden
    }
}

extension Sesame5SettingViewController: CHSesame2Delegate {
    public func onBleDeviceStatusChanged(device: CHDevice,
                                         status: CHDeviceStatus,
                                         shadowStatus: CHDeviceStatus?) {
        if device.deviceId == sesame5.deviceId,
            status == .receivedBle() {
            device.connect() { _ in }
        } else if status.loginStatus == .logined {
            if versionStr == nil {
                getVersionTag()
            }
            autoLockInt = sesame5.mechSetting?.autoLockSecond
            opsLockUInt = sesame5.opsSetting?.opsLockSecond
        }
        executeOnMainThread {
            self.showStatusViewIfNeeded()
        }
    }
}

// MARK: - UIPickerView setting
extension Sesame5SettingViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    // MARK: Picker View DataSource
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
           case 1:  // autoLockView
               return secondSettingValue.count
           case 2:  // opsLockView
               return opsSecondSettingValue.count
           default:
               return 0
           }
    }

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel = view as? UILabel

        if pickerLabel == nil{
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.systemFont(ofSize: 16)
            pickerLabel?.textAlignment = .center
        }
        
        switch pickerView.tag {
         case 1:
             pickerLabel?.text = formatedTimeFromSec(secondSettingValue[row])
         case 2:
             pickerLabel?.text = formatedTimeFromSec(opsSecondSettingValue[row])
         default:
             break
         }
        return pickerLabel!
    }

    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag {
        case 1:  // autoLockView
            secondPickerDidSelectRow(row)
            autoLockView.fold()
        case 2:  // opsSecondView
            opsPickerDidSelectRow(row)
            opsLockView.fold()
        default:
            break
        }
    }
    
    // MARK: 設定Auto Lock秒數
    func secondPickerDidSelectRow(_ row: Int) {
        sesame5.enableAutolock(delay: secondSettingValue[row]) { result  in
            executeOnMainThread {
                switch result {
                case .success(let delay):
                    self.autoLockInt = Int16(delay.data)
                case .failure(let error):
                    L.d(error.errorDescription())
                }
            }
        }
    }
    
    // MARK: 設定Open Sensor秒數
    func opsPickerDidSelectRow(_ row: Int){
        sesame5.opSensorControl(delay: (opsSecondSettingValue[row])){ result in
            switch result{
            case .success(let delay):
                self.opsLockUInt = UInt16(delay.data)
            case .failure(let error):
                L.d(error.errorDescription())
            }
        }
    }
}

// MARK: - DFUHelperDelegate
extension Sesame5SettingViewController: DFUHelperDelegate {
    func dfuStateDidChange(to state: DFUState) {
        switch state {
        case .starting:
            self.dfuView.value = "co.candyhouse.sesame2.StartingSoon".localized
        case .completed:
            self.dfuView.value = "co.candyhouse.sesame2.Succeeded".localized
        case .aborted:
            break
        default:
            break
        }
    }

    func dfuError(_ error: DFUError,
                  didOccurWithMessage message: String) {
        view.makeToast(message)
    }

    func dfuProgressDidChange(for part: Int,
                              outOf totalParts: Int,
                              to progress: Int,
                              currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        dfuView.value = "\(progress)%"
    }
}

// MARK: - INUIAddVoiceShortcutButtonDelegate
extension Sesame5SettingViewController: INUIAddVoiceShortcutButtonDelegate {
    @available(iOS 12.0, *)
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        addVoiceShortcutViewController.delegate = self
        addVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(addVoiceShortcutViewController, animated: true, completion: nil)
    }

    @available(iOS 12.0, *)
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        editVoiceShortcutViewController.delegate = self
        editVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(editVoiceShortcutViewController, animated: true, completion: nil)
    }
}

// MARK: - INUIAddVoiceShortcutViewControllerDelegate
extension Sesame5SettingViewController: INUIAddVoiceShortcutViewControllerDelegate {
    @available(iOS 12.0, *)
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        if voiceShortcut?.shortcut.intent is ToggleSesameIntent {
            sesame5.setVoiceToggle(voiceShortcut!.identifier)
        } else if voiceShortcut?.shortcut.intent is LockSesameIntent {
            sesame5.setVoiceLock(voiceShortcut!.identifier)
        } else if voiceShortcut?.shortcut.intent is UnlockSesameIntent {
            sesame5.setVoiceUnlock(voiceShortcut!.identifier)
        }
        controller.dismiss(animated: true, completion: nil)
    }

    @available(iOS 12.0, *)
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - INUIEditVoiceShortcutViewControllerDelegate
extension Sesame5SettingViewController: INUIEditVoiceShortcutViewControllerDelegate {
    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }

    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {

        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
            if let _ = shortcuts?.filter({ $0.identifier == deletedVoiceShortcutIdentifier && $0.shortcut.intent is ToggleSesameIntent }).first {
                self.sesame5.removeVoiceToggle()
            } else if let _ = shortcuts?.filter({ $0.identifier == deletedVoiceShortcutIdentifier && $0.shortcut.intent is LockSesameIntent }).first {
                self.sesame5.removeVoiceLock()
            } else if let _ = shortcuts?.filter({ $0.identifier == deletedVoiceShortcutIdentifier && $0.shortcut.intent is UnlockSesameIntent }).first {
                self.sesame5.removeVoiceUnlock()
            }
        }

        controller.dismiss(animated: true, completion: nil)
    }

    @available(iOS 12.0, *)
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
extension Sesame5SettingViewController {
    static func instance(_ sesame5: CHSesame5, dismissHandler: ((Bool)->Void)? = nil) -> Sesame5SettingViewController {
        let sesame5SettingViewController = Sesame5SettingViewController(nibName: nil, bundle: nil)
        sesame5SettingViewController.sesame5 = sesame5
        sesame5SettingViewController.dismissHandler = dismissHandler
        sesame5SettingViewController.hidesBottomBarWhenPushed = true
        return sesame5SettingViewController
    }
}

