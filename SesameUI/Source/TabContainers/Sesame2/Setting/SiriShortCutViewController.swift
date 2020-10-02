//
//  SiriShortCutViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/11.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import IntentsUI
import SesameSDK

class SiriShortCutViewController: CHBaseViewController {
    
    // MARK: - Data
    var sesame2: CHSesame2!
    
    @available(iOS 12.0, *)
    public var openSesame2Intent: OpenSesame2Intent {
        let intent = OpenSesame2Intent()
        intent.suggestedInvocationPhrase = "Open Sesame"
        intent.name = Sesame2Store.shared.getSesame2Property(sesame2)?.name ?? sesame2.deviceId.uuidString
        return intent
    }
    
    @available(iOS 12.0, *)
    public var toggleSesame2Intent: ToggleSesame2Intent {
        let intent = ToggleSesame2Intent()
        intent.suggestedInvocationPhrase = "Toggle Sesame"
        intent.name = Sesame2Store.shared.getSesame2Property(sesame2)?.name ?? sesame2.deviceId.uuidString
        return intent
    }
    
    @available(iOS 12.0, *)
    public var lockSesame2Intent: LockSesame2Intent {
        let intent = LockSesame2Intent()
        intent.suggestedInvocationPhrase = "Lock Sesame"
        intent.name = Sesame2Store.shared.getSesame2Property(sesame2)?.name ?? sesame2.deviceId.uuidString
        return intent
    }
    
    // MARK: - UIComponents
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        if #available(iOS 12.0, *) {
            scrollView.addSubview(contentStackView)
            view.addSubview(scrollView)
            contentStackView.axis = .vertical
            contentStackView.alignment = .fill
            contentStackView.spacing = 10
            contentStackView.distribution = .fill
            UIView.autoLayoutStackView(contentStackView, inScrollView: scrollView)
            
            arrangeSubviews()
        } else {
            let label = UILabel(frame: .zero)
            label.text = "Please upgrade to latest iOS version."
            view.addSubview(label)
            label.autoPinCenter()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: ArrangeSubviews
    func arrangeSubviews() {
        if #available(iOS 12.0, *) {
            let topPadding = UIView(frame: .zero)
            topPadding.autoLayoutHeight(60)
            contentStackView.addArrangedSubview(topPadding)
            
            // MARK: Open Sesame
            let openSesame2Label = UILabel(frame: .zero)
            openSesame2Label.textAlignment = .center
            openSesame2Label.font = .boldSystemFont(ofSize: 20)
            openSesame2Label.text = "Open Sesame"
            contentStackView.addArrangedSubview(openSesame2Label)
            
            let openSesame2ButtonContainer = UIView(frame: .zero)
            let openSesame2Button = INUIAddVoiceShortcutButton(style: .whiteOutline)
            openSesame2Button.shortcut = INShortcut(intent: openSesame2Intent)
            openSesame2Button.delegate = self
            
            contentStackView.addArrangedSubview(openSesame2ButtonContainer)
            openSesame2ButtonContainer.addSubview(openSesame2Button)
            openSesame2ButtonContainer.autoLayoutHeight(40)
            openSesame2Button.autoPinCenterX()
            openSesame2Button.autoLayoutWidth(200)
            openSesame2Button.autoLayoutHeight(40)
            
            // MARK: Lock Sesame
            let lockSesame2Label = UILabel(frame: .zero)
            lockSesame2Label.textAlignment = .center
            lockSesame2Label.font = .boldSystemFont(ofSize: 20)
            lockSesame2Label.text = "Lock Sesame"
            contentStackView.addArrangedSubview(lockSesame2Label)
            
            let lockSesame2ButtonContainer = UIView(frame: .zero)
            let lockSesame2Button = INUIAddVoiceShortcutButton(style: .whiteOutline)
            lockSesame2Button.shortcut = INShortcut(intent: lockSesame2Intent)
            lockSesame2Button.delegate = self
            
            contentStackView.addArrangedSubview(lockSesame2ButtonContainer)
            lockSesame2ButtonContainer.addSubview(lockSesame2Button)
            lockSesame2ButtonContainer.autoLayoutHeight(40)
            lockSesame2Button.autoPinCenterX()
            lockSesame2Button.autoLayoutWidth(200)
            lockSesame2Button.autoLayoutHeight(40)
            
            // MARK: Toggle Sesame
            let toggleSesame2Label = UILabel(frame: .zero)
            toggleSesame2Label.textAlignment = .center
            toggleSesame2Label.font = .boldSystemFont(ofSize: 20)
            toggleSesame2Label.text = "Toggle Sesame"
            contentStackView.addArrangedSubview(toggleSesame2Label)

            let toggleSesame2ButtonContainer = UIView(frame: .zero)
            let toggleSesame2Button = INUIAddVoiceShortcutButton(style: .whiteOutline)
            toggleSesame2Button.shortcut = INShortcut(intent: toggleSesame2Intent)
            toggleSesame2Button.delegate = self
            toggleSesame2ButtonContainer.addSubview(toggleSesame2Button)
            contentStackView.addArrangedSubview(toggleSesame2ButtonContainer)
            toggleSesame2ButtonContainer.autoLayoutHeight(40)
            toggleSesame2Button.autoPinCenterX()
            toggleSesame2Button.autoLayoutWidth(200)
            toggleSesame2Button.autoLayoutHeight(40)
        }
    }
}

// MARK: - INUIAddVoiceShortcutButtonDelegate
extension SiriShortCutViewController: INUIAddVoiceShortcutButtonDelegate {
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
extension SiriShortCutViewController: INUIAddVoiceShortcutViewControllerDelegate {
    @available(iOS 12.0, *)
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - INUIEditVoiceShortcutViewControllerDelegate
extension SiriShortCutViewController: INUIEditVoiceShortcutViewControllerDelegate {
    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @available(iOS 12.0, *)
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Designated initializer
extension SiriShortCutViewController {
    static func instanceWithSesame2(_ sesame2: CHSesame2) -> SiriShortCutViewController {
        let siriShortcutViewController = SiriShortCutViewController(nibName: nil, bundle: nil)
        siriShortcutViewController.sesame2 = sesame2
        return siriShortcutViewController
    }
}
