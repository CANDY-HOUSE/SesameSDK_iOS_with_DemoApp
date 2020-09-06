//
//  Sesame2SettingVC.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/10/14.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import UIKit
import CoreBluetooth
import SesameSDK
import iOSDFULibrary

public class Sesame2SettingViewController: CHBaseViewController {
    private var dfuHelper: DFUHelper?
    var viewModel: Sesame2SettingViewModel!
    
    // UUID
    @IBOutlet weak var uuidTitleLabel: UILabel!
    @IBOutlet weak var uuidValueLabel: UILabel!
    
    // Angle
    @IBOutlet weak var angleLabel: UILabel!
    @IBOutlet weak var arrowImg: UIImageView!
    
    // SSM2 Name
    @IBOutlet weak var changenameLb: UILabel!
    
    // DFU
    @IBOutlet weak var dfuLabel: UILabel!
    @IBOutlet weak var version: UILabel!
    
    // AutoLock
    @IBOutlet weak var autoLockTitleLabel: UILabel!
    @IBOutlet weak var autoLockValueLabel: UILabel!
    @IBOutlet weak var autoLockSwitch: UISwitch!
    @IBOutlet weak var secondPicker: UIPickerView!
    
    // advInterval
    
    @IBOutlet weak var advIntervalContainer: UIView?
    @IBOutlet weak var advIntervalLabel: UILabel?
    @IBOutlet weak var advIntervalValueLabel: UILabel?
    @IBOutlet weak var advIntervalPicker: UIPickerView?
    
    // txPower
    @IBOutlet weak var txPowerContainer: UIView?
    @IBOutlet weak var txPowerLabel: UILabel?
    @IBOutlet weak var txPowerValueLabel: UILabel?
    @IBOutlet weak var txPowerPicker: UIPickerView?
    
    // Reset Sesame
    @IBOutlet weak var resetSesameButton: UIButton!
    
    // Drop Key
    @IBOutlet weak var dropKeyButton: UIButton!
    
    // Sharing
    @IBOutlet weak var sharingButtonContainer: UIView!
    @IBOutlet weak var sharingButton: UIButton!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(viewModel != nil, "Sesame2SettingViewModel should not be nil.")
        
        viewModel.statusUpdated = { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            switch status {
            case .loading:
                executeOnMainThread {
                    ViewHelper.showLoadingInView(view: strongSelf.view)
                }
            case .update:
                executeOnMainThread {
                    strongSelf.refreshUI()
                    ViewHelper.hideLoadingView(view: strongSelf.view)
                }
            case .finished(let result):
                executeOnMainThread {
                    switch result {
                    case .success(_):
                        strongSelf.view.makeToast("co.candyhouse.sesame-sdk-test-app.CompletelySet".localized)
                        ViewHelper.hideLoadingView(view: strongSelf.view)
                    case .failure(let error):
                        switch error {
                        case LockAngleSettingViewModel.LockAngleError.tooClose:
                            strongSelf.view.makeToast("co.candyhouse.sesame-sdk-test-app.TooClose".localized)
                        default:
                            strongSelf.view.makeToast(error.errorDescription())
                        }
                        ViewHelper.hideLoadingView(view: strongSelf.view)
                    }
                }
            }
        }
        
        autoLockSwitch.addTarget(viewModel, action: #selector(Sesame2SettingViewModel.autoLockSwitchChanged(sender:)), for: .valueChanged)

        refreshUI()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear()
        titleLabel.text = viewModel.title
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.viewDidDisappear()
    }
    
    func refreshUI()  {
        titleLabel.text = viewModel.title
        autoLockSwitch.isOn = viewModel.isAutoLockSwitchOn
        autoLockSwitch.isEnabled = viewModel.autolockSwitchIsEnabled
        
        autoLockTitleLabel.isHidden = viewModel.isAutoLockTitleLabelHidden
        autoLockValueLabel.isHidden = viewModel.isAutoLockValueLabelHidden
        
        changenameLb.text = viewModel.changeNameIndicator
        angleLabel.text = viewModel.angleIndicator
        dfuLabel.text = viewModel.dfuIndicator
        
        autoLockTitleLabel.text = viewModel.autoLockTitleLabelText
        autoLockValueLabel.text = viewModel.autoLockValueLabelText
        
        resetSesameButton.setTitle(viewModel.removeSesameText, for: .normal)
        dropKeyButton.setTitle(viewModel.dropKeyText, for: .normal)
        sharingButton.setTitle(viewModel.share, for: .normal)
        
        resetSesameButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        dropKeyButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        sharingButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        
        arrowImg.image = UIImage.SVGImage(named: viewModel.arrowImg)
        secondPicker.isHidden = viewModel.isHiddenSecondPicker
        
        advIntervalLabel?.text = viewModel.advIntervalTitle
        advIntervalValueLabel?.text = viewModel.advInterval
        txPowerLabel?.text = viewModel.txPowerTitle
        txPowerValueLabel?.text = viewModel.txPower
        advIntervalPicker?.isHidden = viewModel.isHiddenAdvIntervalPicker
        txPowerPicker?.isHidden = viewModel.isHiddenTxPowerPicker
        
        version.text = viewModel.sesame2VersionText
        
        uuidTitleLabel.text = viewModel.uuidTitleText
        uuidValueLabel.text = viewModel.uuidValueText

        autoLockSwitch.onTintColor = viewModel.autoLockSwitchColor
        secondPicker.selectRow(viewModel.secondPickerSelectedRow, inComponent: 0, animated: false)
        advIntervalPicker?.selectRow(viewModel.advIntervalPickerSelectedRow, inComponent: 0, animated: false)
        txPowerPicker?.selectRow(viewModel.txPowerPickerSelectedRow, inComponent: 0, animated: false)
        

        let debugViews = [
            advIntervalLabel,
            advIntervalValueLabel,
            advIntervalPicker,
            advIntervalContainer,
            txPowerLabel,
            txPowerValueLabel,
            txPowerPicker,
            txPowerContainer
        ]
        if !CHConfiguration.shared.isDebugModeEnabled() {
            for debugView in debugViews {
                debugView?.removeFromSuperview()
            }
        }
    }
    
    @IBAction func autolockSwitch(_ sender: UISwitch) {
    }
    
    @IBAction func DFU(_ sender: UIButton) {
        showDFUAlertFrom(sender: sender, dfuProcess: { [weak self] progressIndicator in
            self?.viewModel.dfuApplicationWithObserver(progressIndicator)
        }) { [weak self] in
            self?.viewModel.viewDidDisappear()
        }
    }
    
    @IBAction func autolockSecond(_ sender: Any) {
        viewModel.autolockSecondTapped()
    }
    
    @IBAction func advIntervalConfigTapped(_ sender: Any) {
        viewModel.advIntervalConfigTapped()
    }
    
    @IBAction func txPowerConfigTapped(_ sender: Any) {
        viewModel.txPowerConfgTapped()
    }
    
    @IBAction func unRegister(_ sender: UIButton) {
        let check = UIAlertAction.addAction(title: viewModel.removeSesameText,
                                            style: .destructive) { (action) in
            self.viewModel.deleteSeesameAction()
        }
        UIAlertController.showAlertController(sender,style: .actionSheet, actions: [check])
    }
    
    @IBAction func dropKeyTapped(_ sender: UIButton) {
        let check = UIAlertAction.addAction(title: viewModel.dropKeyText,
                                            style: .destructive) { (action) in
                                                self.viewModel.dropKey()
        }
        UIAlertController.showAlertController(sender, style: .actionSheet, actions: [check])
        
    }
    
    @IBAction func angleSet(_ sender: UIButton) {
        viewModel.setAngleTapped()
    }
    
    @IBAction func changeName(_ sender: UIButton) {

        CHSesame2ChangeNameDialog.show(viewModel.renamePlaceholder()) { name in
            if name == "" {
                self.view.makeToast(self.viewModel.enterSesameName)
                return
            }
            self.viewModel.rename(name)
            DispatchQueue.main.async {
                self.refreshUI()
            }
        }
    }
    
    @IBAction func modifyHistoryTag(_ sender: Any) {
        CHSesame2ChangeNameDialog.show(viewModel.historyTagPlaceholder(), title: "Change History Tag".localized, hint: "") { historyTag in
            if historyTag == "" {
                self.view.makeToast(self.viewModel.enterSesameName)
                return
            }
            self.viewModel.modifyHistoryTag(historyTag)
            DispatchQueue.main.async {
                self.refreshUI()
            }
        }
    }
    
    
    @IBAction func sharing(_ sender: Any) {
        viewModel.shareSesame2Tapped()
    }
    
    deinit {
//        L.d("Sesame2SettingViewController deinit")
    }
}
