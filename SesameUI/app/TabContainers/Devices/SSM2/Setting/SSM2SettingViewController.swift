//
//  SSM2SettingVC.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/10/14.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import UIKit
import CoreBluetooth
import SesameSDK
import iOSDFULibrary

public class SSM2SettingViewController: CHBaseViewController {
    private var dfuHelper: DFUHelper?
    var viewModel: SSM2SettingViewModel!
    @IBOutlet weak var uuidTitleLabel: UILabel!
    @IBOutlet weak var uuidValueLabel: UILabel!
    
    @IBOutlet weak var memberCollectionViewContainerHeight: NSLayoutConstraint! {
        didSet {
//            if !isSignedIn {
//                memberCollectionViewContainer.isHidden = true
//                memberCollectionViewContainerHeight.constant = 0
//            }
        }
    }
    @IBOutlet weak var memberCollectionViewContainer: UIView! {
        didSet {
//            if !isSignedIn {
//                memberCollectionViewContainer.isHidden = true
//                memberCollectionViewContainer.frame = .zero
//            }
        }
    }
    
    @IBOutlet weak var arrowImg: UIImageView!
    
    @IBOutlet weak var autoLockLabel1: UILabel!
    @IBOutlet weak var autoLockLabel2: UILabel!
    
    @IBOutlet weak var changenameLb: UILabel!
    @IBOutlet weak var angleLabel: UILabel!
    @IBOutlet weak var dfuLabel: UILabel!
    @IBOutlet weak var autoLockLabel3: UILabel!
    @IBOutlet weak var resetSesameButton: UIButton!
    @IBOutlet weak var dropKeyButton: UIButton!
    @IBOutlet weak var autoLockSwitch: UISwitch!
    @IBOutlet weak var version: UILabel!
    @IBOutlet weak var autoLockSecond: UILabel!
    @IBOutlet weak var secondPicker: UIPickerView!
    @IBOutlet weak var sharingButtonContainer: UIView!
    @IBOutlet weak var sharingButton: UIButton!
    @IBOutlet weak var modifyHistoryTagLabel: UILabel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(viewModel != nil, "SSM2SettingViewModel should not be nil.")
        
        viewModel.statusUpdated = { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            switch status {
            case .loading:
                executeOnMainThread {
                    ViewHelper.showLoadingInView(view: strongSelf.view)
                }
            case .received:
                executeOnMainThread {
                    strongSelf.refreshUI()
                    ViewHelper.hideLoadingView(view: strongSelf.view)
                }
            case .finished(let result):
                executeOnMainThread {
                    switch result {
                    case .success(_):
                        strongSelf.view.makeToast("Completely Set".localStr)
                        ViewHelper.hideLoadingView(view: strongSelf.view)
                    case .failure(let error):
                        switch error {
                        case LockAngleSettingViewModel.LockAngleError.tooClose:
                            strongSelf.view.makeToast("Too close")
                        default:
                            strongSelf.view.makeToast(error.errorDescription())
                        }
                        ViewHelper.hideLoadingView(view: strongSelf.view)
                    }
                }
            }
        }
        
        autoLockSwitch.addTarget(viewModel, action: #selector(SSM2SettingViewModel.autoLockSwitchChanged(sender:)), for: .valueChanged)

        refreshUI()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.title = viewModel.title
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.viewDidDisappear()
    }
    
    func refreshUI()  {
        navigationItem.title = viewModel.title
        autoLockSwitch.isOn = viewModel.isAutoLockSwitchOn
        autoLockSwitch.isEnabled = viewModel.autolockSwitchIsEnabled
        
        autoLockLabel1.isHidden = viewModel.isAutoLockLabel1Hidden
        autoLockLabel2.isHidden = viewModel.isAutoLockLabel2Hidden
        autoLockLabel3.isHidden = viewModel.isAutoLockLabel3Hidden
        autoLockSecond.isHidden = viewModel.isAutoLockSecondHidden
        
        changenameLb.text = viewModel.changeNameIndicator
        angleLabel.text = viewModel.angleIndicator
        dfuLabel.text = viewModel.dfuIndicator
        
        autoLockLabel1.text = viewModel.autoLockLabel1Text
        autoLockLabel2.text = viewModel.autoLockLabel2Text
        autoLockLabel3.text = viewModel.autoLockLabel3Text
        autoLockSecond.text = viewModel.autoLockSecondText
        
        resetSesameButton.setTitle(viewModel.removeSesameText, for: .normal)
        dropKeyButton.setTitle(viewModel.dropKeyText, for: .normal)
        
        arrowImg.image = UIImage.SVGImage(named: viewModel.arrowImg)
        secondPicker.isHidden = viewModel.secondPickerIsHidden
        
        version.text = viewModel.ssmVersionText
        
        uuidTitleLabel.text = viewModel.uuidTitleText
        uuidValueLabel.text = viewModel.uuidValueText
        
        modifyHistoryTagLabel.text = viewModel.modifyHistoryTagText
    }
    
    @IBAction func AutolockSwitch(_ sender: UISwitch) {
    }
    
    @IBAction func DFU(_ sender: Any) {

        let check = UIAlertAction
            .addAction(title: viewModel.dfuActionText(),
                       style: .destructive) { (action) in
                        let progressIndicator = TemporaryFirmwareUpdateClass(self) { success in
                            
                        }
                        progressIndicator.dfuInitialized {
                            self.viewModel.cancelDFU()
                        }
                        self.viewModel.dfuActionWithObserver(progressIndicator)
                        
        }
        if let view = sender as? UIView {
            UIAlertController.showAlertController(view,
                                                  style: .actionSheet,
                                                  actions: [check])
        }
    }
    
    @IBAction func autolockSecond(_ sender: Any) {
        viewModel.autolockSecondTapped()
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

        CHSSMChangeNameDialog.show(viewModel.renamePlaceholder()) { name in
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
        CHSSMChangeNameDialog.show(viewModel.historyTagPlaceholder()) { historyTag in
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
        viewModel.shareSSMTapped()
    }
    
    deinit {
//        L.d("SSM2SettingViewController deinit")
    }
}
