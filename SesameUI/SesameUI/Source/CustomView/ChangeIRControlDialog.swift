//
//  ChangeIRControlDialog.swift
//  SesameUI
//
//  Created by eddy on 2024/1/29.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

enum IRControlType: Int {
    case unknow
    case start
    case end
}

public class ChangeIRControlDialog: UIViewController {
    var okHandler:((ChangeIRControlDialog)->Void)?
    var cancelHandler: ((ChangeIRControlDialog)->Void)?
    var testHandler:((ChangeIRControlDialog)->Void)?
    var value: String =  ""
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var testButton: UIButton!
    
    var controlType: IRControlType = .start {
        didSet{
            configureType()
        }
    }
    
    @IBAction func okTapped(_ sender: Any) {
        self.dismiss(animated: false) { [weak self] in
            guard let self = self else { return }
            self.okHandler?(self)
        }
    }

    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: false) { [weak self] in
            guard let self = self else { return }
            self.cancelHandler?(self)
        }
    }

    @IBAction func testTapped(_ sender: Any) {
        self.testHandler?(self)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        configureType()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func configureType() {
        switch controlType {
        case .unknow: break
        case .start:
            testButton.isHidden = true
            loadingView.startAnimating()
            okButton.isHidden = true
            titleLabel.text = "学习中"
        case .end:
            loadingView.stopAnimating()
            testButton.isHidden = false
            okButton.isHidden = false
            titleLabel.text = "学习完成"
        }
    }
    
    func setupViews() {
        cancelButton.setTitle("取消", for: .normal)
        okButton.setTitle("保存数据".localized.localized, for: .normal)
        titleLabel.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        okButton.titleLabel?.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        cancelButton.titleLabel?.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        testButton.layer.borderColor = UIColor.sesame2Gray.cgColor
        testButton.setTitle("点击测试", for: .normal)
        loadingView.color = UIColor.black
    }
    
    @objc
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            view.frame.origin.y = 0
            let overlap = alertView.frame.maxY - (view.frame.maxY - (keyboardSize.height))
            if overlap > 0 {
                view.frame.origin.y -= overlap + 40
            }
        }
    }

    @objc
    func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0
    }
}

extension ChangeIRControlDialog {
    static func show(cancel: @escaping (ChangeIRControlDialog) -> Void,
                     test: @escaping (ChangeIRControlDialog) -> Void,
                     ok: @escaping (ChangeIRControlDialog) -> Void) -> ChangeIRControlDialog {
        
        let myAlert = UIStoryboard.viewControllers.changeIRControlDialog!
        myAlert.cancelHandler = cancel
        myAlert.okHandler = ok
        myAlert.testHandler = test
        myAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        myAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(myAlert, animated: true, completion: nil)
        } else {
            UIApplication.shared.delegate?.window??.rootViewController?.present(myAlert, animated: true, completion: nil)
        }
        return myAlert
    }
}

