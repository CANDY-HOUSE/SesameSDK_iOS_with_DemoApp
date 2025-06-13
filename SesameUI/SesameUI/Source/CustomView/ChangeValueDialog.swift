//
//  CHSesame2ChangeNameDialog.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2020/1/13.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK

public class ChangeValueDialog: UIViewController {
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.first?.view == backgroundView && !valueTextField.isFirstResponder {
            cancelTapped(touches)
        }
        view.endEditing(true)
    }
    var overlayWindow: UIWindow?
    var callback:(_ newValue: String) -> Void = { newValue in }
    var cancelHandler: (()->Void)?
    var value: String =  ""
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueDescriptionLabel: UILabel!
    @IBOutlet weak var valueTextField: UITextField! {
        didSet {
            valueTextField.delegate = self
            valueTextField.becomeFirstResponder()
        }
    }
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    
    var titleLBText: String = "co.candyhouse.sesame2.EditName".localized
    var valueDescription: String = "co.candyhouse.sesame2.GiveSesameAName".localized
    var valuePlaceHolder: String = ""

    deinit {
        L.d("======== ChangeValueDialog deinit ======== ")
    }
    
    @IBAction func okTapped(_ sender: Any) {
        if let newValue = valueTextField.text,
            newValue != "" {
            self.valueTextField.resignFirstResponder()
            if (self.presentingViewController != nil) {
                self.dismiss(animated: false) { [weak self] in
                    guard let self = self else { return }
                    self.callback(newValue)
                }
            } else {
                self.willMove(toParent: nil)
                self.view.removeFromSuperview()
                self.removeFromParent()
                self.callback(newValue)
            }
        }
    }

    @IBAction func cancelTapped(_ sender: Any) {
        self.valueTextField.resignFirstResponder()
        if (self.presentingViewController != nil) {
            self.dismiss(animated: false) { [weak self] in
                guard let self = self else { return }
                cancelHandler?()
            }
        } else {
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
            cancelHandler?()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        valueDescriptionLabel.text = valueDescription
        titleLabel.text = titleLBText
        cancelButton.setTitle("co.candyhouse.sesame2.Cancel".localized, for: .normal)
        okButton.setTitle("co.candyhouse.sesame2.OK".localized.localized, for: .normal)
        titleLabel.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        okButton.titleLabel?.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        cancelButton.titleLabel?.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        valueTextField.text = value
        valueTextField.placeholder = valuePlaceHolder
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
    
    static func show(_ oldValue: String,
                     callBack: @escaping (_ newValue: String)->Void) {
        
        let myAlert = UIStoryboard.viewControllers.changeValueDialog!
        myAlert.value = oldValue
        myAlert.callback = callBack
        myAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        myAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(myAlert, animated: true, completion: nil)
        } else {
            UIApplication.shared.delegate?.window??.rootViewController?.present(myAlert, animated: true, completion: nil)
        }
    }
    
    @discardableResult
    static func show(_ oldValue: String,
                     title: String = "",
                     placeHolder: String = "",
                     hint: String = "",
                     callBack:@escaping (_ newValue: String)->Void) -> ChangeValueDialog {
        let setValueDialog = UIStoryboard.viewControllers.changeValueDialog!
        setValueDialog.titleLBText = title
        setValueDialog.valueDescription = hint
        setValueDialog.callback = callBack
        setValueDialog.value = oldValue
        setValueDialog.valuePlaceHolder = placeHolder
        setValueDialog.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        setValueDialog.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(setValueDialog, animated: true, completion: nil)
        } else {
            UIApplication.shared.delegate?.window??.rootViewController?.present(setValueDialog, animated: true, completion: nil)
        }
        return setValueDialog
    }
    
    static func showInView(_ oldValue: String,
                                 viewController: UIViewController,
                                 title: String = "",
                                 hint: String = "",
                                 callBack:@escaping (_ newValue: String)->Void){
        let setValueDialog = UIStoryboard.viewControllers.changeValueDialog!
        setValueDialog.titleLBText = title
        setValueDialog.valueDescription = hint
        setValueDialog.callback = callBack
        setValueDialog.value = oldValue
        UIApplication.shared.delegate?.window??.rootViewController!.addChild(setValueDialog)
        UIApplication.shared.delegate?.window??.rootViewController!.view.addSubview(setValueDialog.view)
        setValueDialog.didMove(toParent: UIApplication.shared.delegate?.window??.rootViewController)
    }
    
    static func showInNewWindow(_ oldValue: String,
                                 viewController: UIViewController,
                                 title: String = "",
                                 hint: String = "",
                                 callBack:@escaping (_ newValue: String)->Void){
        let setValueDialog = UIStoryboard.viewControllers.changeValueDialog!
        setValueDialog.titleLBText = title
        setValueDialog.valueDescription = hint
        setValueDialog.callback = callBack
        setValueDialog.value = oldValue
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.windowLevel = .alert + 1
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        window.rootViewController?.present(setValueDialog, animated: true, completion: nil)
        setValueDialog.overlayWindow = window
    }
}

extension ChangeValueDialog: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
