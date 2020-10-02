//
//  MeViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/14.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

class MeViewController: CHBaseViewController {
    
    // MARK: - UI component
    lazy var historyTagView: HistoryTagView = {
        let nib = Bundle.main.loadNibNamed("HistoryTagView", owner: nil, options: nil)
        let historyTagView = nib!.first as! HistoryTagView
        historyTagView.historyTagButton.setTitle("ドラえもん".localized, for: .normal)
        historyTagView.historyTagButton.addTarget(self, action: #selector(historyTagTapped), for: .touchUpInside)
        return historyTagView
    }()
    
    var debugModeView: Sesame2ToggleSettingView!
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)
    
    lazy var popUpMenuControl: PopUpMenuControl = {
        let y = UIApplication.shared.statusBarFrame.height + 44
        let frame = CGRect(x: 0, y: y, width: view.bounds.width, height: view.bounds.height - y)
        let popUpMenuControl = PopUpMenuControl(frame: frame)
        popUpMenuControl.delegate = self
        return popUpMenuControl
    }()

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            let previouseColor = navigationController?.navigationBar.standardAppearance.backgroundColor ?? .white
            navigationBarTintColor = .init(current: UIColor.white, previous: previouseColor)
        } else {
            let previouseColor = navigationController?.navigationBar.tintColor ?? .white
            navigationBarTintColor = .init(current: UIColor.white, previous: previouseColor)
        }
        
        if #available(iOS 13.0, *) {
            self.navigationController?.navigationBar.standardAppearance.shadowColor = .clear
        } else {
            // Fallback on earlier versions
        }
        
        view.backgroundColor = .sesame2Gray
        
        scrollView.addSubview(contentStackView)
        view.addSubview(scrollView)
        
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 0
        contentStackView.distribution = .fill
        
        UIView.autoLayoutStackView(contentStackView, inScrollView: scrollView)
        
        historyTagView.autoLayoutHeight(100)
        
        contentStackView.addArrangedSubview(historyTagView)
        contentStackView.addArrangedSubview(Sesame2SettingViewGenerator.seperatorWithStyle(.thick))
        debugModeView = Sesame2SettingViewGenerator.toggle { [unowned self] toggle in
            CHConfiguration.shared.enableDebugMode((toggle as! UISwitch).isOn)
            self.refreshUI()
        }
        debugModeView.title = "Debug Mode"
        debugModeView.switchView.isOn = CHConfiguration.shared.isDebugModeEnabled()
        contentStackView.addArrangedSubview(debugModeView)
        
        let rightButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: "icons_outlined_addoutline"),
                                              style: .done,
                                              target: self,
                                              action: #selector(handleRightBarButtonTapped(_:)))
        navigationItem.rightBarButtonItem = rightButtonItem
        
        let versionLabel = VersionLabel()
        view.addSubview(versionLabel)
        versionLabel.autoPinCenterX()
        versionLabel.autoPinBottomToSafeArea()
        versionLabel.autoPinWidth()
        versionLabel.autoLayoutHeight(40)
        
        scrollView.backgroundColor = .sesame2Gray
        view.backgroundColor = .white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshUI()
    }
    
    // MARK: - User events
    @objc func historyTagTapped() {
        
        getHistoryTagPlaceholder { placeHolder in
            ChangeValueDialog.show(placeHolder,
                                           title: "co.candyhouse.sesame-sdk-test-app.changeHistoryTag".localized,
                                           hint: self.changeHistoryTagHint()) { historyTag in
                if historyTag == "" {
                    self.view.makeToast("co.candyhouse.sesame-sdk-test-app.EnterSesameName".localized)
                    return
                }
                self.modifyHistoryTag(historyTag)
                DispatchQueue.main.async {
                    self.refreshUI()
                }
            }
        }
    }
    
    // MARK: - Methods
    func getHistoryTagPlaceholder(_ handler: @escaping (String)->Void) {
        CHDeviceManager.shared.getSesame2s { result in
            switch result {
            case .success(let sesame2s):
                if let historyTag = sesame2s.data.first?.getHistoryTag() {
                    let historyTagText = String(data: historyTag, encoding: .utf8) ?? "ドラえもん".localized
                    executeOnMainThread {
                        handler(historyTagText)
                    }
                }
            case .failure(let error):
                self.view.makeToast(error.errorDescription())
                executeOnMainThread {
                    handler("ドラえもん".localized)
                }
            }
        }
    }
    
    func changeHistoryTagHint() -> String {
        CHConfiguration.shared.isDebugModeEnabled() ? "History Tag" : ""
    }
    
    func modifyHistoryTag(_ historyTag: String) {
        guard let encodedHistoryTag = historyTag.data(using: .utf8) else {
            let error = NSError(domain: "", code: 0, userInfo: ["message":"Unsupported format"])
            view.makeToast(error.errorDescription())
            return
        }
        
        CHDeviceManager.shared.getSesame2s { result in
            switch result {
            case .success(let sesame2s):
                
                for sesame2 in sesame2s.data {
                    sesame2.setHistoryTag(encodedHistoryTag) { result in
                        switch result {
                        case .success(_):
                            self.refreshUI()
                            WatchKitFileTransfer.transferKeysToWatch()
                        case .failure(let error):
                            self.view.makeToast(error.errorDescription())
                        }
                    }
                }
                
            case .failure(let error):
                executeOnMainThread {
                    self.view.makeToast(error.errorDescription())
                }
            }
        }
    }
    
    func refreshUI() {
        CHDeviceManager.shared.getSesame2s { result in
            switch result {
            case .success(let sesame2s):
                if let historyTag = sesame2s.data.first?.getHistoryTag() {
                    let historyTagText = String(data: historyTag, encoding: .utf8) ?? "ドラえもん".localized
                    executeOnMainThread {
                        self.historyTagView.historyTagButton.setTitle(historyTagText, for: .normal)
                    }
                }
            case .failure(let error):
                self.view.makeToast(error.errorDescription())
            }
        }
        if CHConfiguration.shared.isDebugModeEnabled() {
            historyTagView.historyTagHintLabel.text = "History Tag"
        } else {
            historyTagView.historyTagHintLabel.text = ""
        }
    }
}

// MARK: - PopUpMenuDelegate
extension MeViewController: PopUpMenuDelegate {
    
    @objc private func handleRightBarButtonTapped(_ sender: Any) {
        if self.popUpMenuControl.superview != nil {
            hideMoreMenu()
        } else {
            showMoreMenu()
        }
    }
    
    private func hideMoreMenu(animated: Bool = true) {
        popUpMenuControl.hide(animated: animated)
    }
    
    private func showMoreMenu() {
        popUpMenuControl.show(in: self.view)
    }
    
    func popUpMenu(_ menu: PopUpMenu, didTap item: PopUpMenuItem) {
        switch item.type {
        case .addDevices:
            presentRegisterSesame2ViewController()
        case .receiveKey:
            presentScanViewController()
        }
        hideMoreMenu(animated: false)
    }
    
    func presentRegisterSesame2ViewController() {
        let registerSesame2ViewController = RegisterSesame2ViewController.instance { isRegisteredSesame2 in
            if isRegisteredSesame2 {
                self.tabBarController?.selectedIndex = 0
            }
        }
        present(registerSesame2ViewController.navigationController!, animated: true, completion: nil)
    }
    
    func presentScanViewController() {
        let qrCodeScanViewController = QRCodeScanViewController.instance() { isReceivedKey in
            if isReceivedKey {
                self.tabBarController?.selectedIndex = 0
            }
        }
        present(qrCodeScanViewController, animated: true, completion: nil)
    }
}

// MARK: - Designated initiate
extension MeViewController {
    static func instance() -> MeViewController {
        let meViewController = MeViewController(nibName: nil, bundle: nil)
        let _ = UINavigationController(rootViewController: meViewController)
        return meViewController
    }
}
