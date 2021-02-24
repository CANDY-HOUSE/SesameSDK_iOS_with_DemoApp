//
//  ChangeValuesDialog.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/11/9.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

class ChangeValuesDialog: UIViewController {
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.first?.view == backgroundView &&
            !valueTextField.isFirstResponder &&
            !secondValueTextField.isFirstResponder {
            cancelTapped(touches)
        }
        view.endEditing(true)
    }
    var callback:(_ newValue: String, _ secondNewValue: String) -> Void = { newValue, secondNewValue  in
        
    }
    var value: String =  ""
    var secondValue: String = ""

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var alertView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var valueDescriptionLabel: UILabel!
    @IBOutlet weak var valueTextField: UITextField! {
        didSet {
            valueTextField.delegate = self
        }
    }
    
    @IBOutlet weak var secondValueTextField: UITextField! {
        didSet {
            secondValueTextField.delegate = self
        }
    }
    @IBOutlet weak var secondValueDescriptionLabel: UILabel!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    
    var titleLBText: String = "co.candyhouse.sesame2.EditSesameName".localized
    var valueDescription: String = "co.candyhouse.sesame2.GiveSesameAName".localized
    var secondValueDescription: String = ""

    @IBAction func okTapped(_ sender: Any) {
        if let newValue = valueTextField.text,
           newValue != "", let secondNewValue = secondValueTextField.text {
            self.valueTextField.resignFirstResponder()
            self.secondValueTextField.resignFirstResponder()
            self.dismiss(animated: true, completion: nil)
            self.callback(newValue, secondNewValue)
        }
    }

    @IBAction func cancelTapped(_ sender: Any) {
        self.valueTextField.resignFirstResponder()
        self.secondValueTextField.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = titleLBText
        cancelButton.setTitle("co.candyhouse.sesame2.Cancel".localized, for: .normal)
        okButton.setTitle("co.candyhouse.sesame2.OK".localized.localized, for: .normal)
        titleLabel.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        okButton.titleLabel?.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        cancelButton.titleLabel?.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        valueTextField.text = value
        valueDescriptionLabel.text = valueDescription
        secondValueTextField.text = secondValue
        secondValueDescriptionLabel.text = secondValueDescription
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            view.frame.origin.y = 0
            let overlap = alertView.frame.maxY - (view.frame.maxY - (keyboardSize.height))
            if overlap > 0 {
                view.frame.origin.y -= overlap
            }
        }
    }

    @objc
    func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0
    }
    
    static func show(_ oldValue: String,
                     title: String,
                     hint: String,
                     secondOldValue: String,
                     secondHint: String,
                     callback: @escaping (_ newValue: String, _ secondNewValue: String) -> Void) {
        
        let setValueDialog = UIStoryboard.viewControllers.changeValuesDialog!
        setValueDialog.callback = callback
        setValueDialog.titleLBText = title
        
        setValueDialog.valueDescription = hint
        setValueDialog.value = oldValue
        
        setValueDialog.secondValue = secondOldValue
        setValueDialog.secondValueDescription = secondHint
        
        setValueDialog.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        setValueDialog.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(setValueDialog, animated: true, completion: nil)
        } else {
            UIApplication.shared.delegate?.window??.rootViewController?.present(setValueDialog, animated: true, completion: nil)
        }
    }
}

extension ChangeValuesDialog: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
