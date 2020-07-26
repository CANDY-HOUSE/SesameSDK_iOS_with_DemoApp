//
//  Sesame2AutoLock.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/11/12.
//  Copyright © 2019 CandyHouse. All rights reserved.
//


import UIKit
import CoreBluetooth
import SesameSDK

extension Sesame2SettingViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch pickerView {
        case secondPicker:
            return viewModel.columnOfAutoLock()
        case advIntervalPicker:
            return viewModel.columnOfAdvInterval()
        case txPowerPicker:
            return viewModel.columnOfTxPower()
        default:
            return 0
        }
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case secondPicker:
            return viewModel.rowOfAutoLock()
        case advIntervalPicker:
            return viewModel.rowOfAdvInterval()
        case txPowerPicker:
            return viewModel.rowOfTxPower()
        default:
            return 0
        }
    }

    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel = view as? UILabel
        
        switch pickerView {
        case secondPicker:
            if pickerLabel == nil{
                pickerLabel = UILabel()
                pickerLabel?.font = UIFont.systemFont(ofSize: 16)
                pickerLabel?.textAlignment = .center
                pickerLabel?.text = viewModel.secondPickerTextForRow(row)
            }
            return pickerLabel!
        case advIntervalPicker:
            if pickerLabel == nil{
                pickerLabel = UILabel()
                pickerLabel?.font = UIFont.systemFont(ofSize: 16)
                pickerLabel?.textAlignment = .center
                pickerLabel?.text = viewModel.advIntervalPickerTextForRow(row)
            }
            return pickerLabel!
        case txPowerPicker:
            if pickerLabel == nil{
                pickerLabel = UILabel()
                pickerLabel?.font = UIFont.systemFont(ofSize: 16)
                pickerLabel?.textAlignment = .center
                pickerLabel?.text = viewModel.txPowerPickerTextForRow(row)
            }
            return pickerLabel!
        default:
            return UIView()
        }
    }
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case secondPicker:
            viewModel.secondPickerDidSelectRow(row)
        case advIntervalPicker:
            viewModel.advPickerDidSelectRow(row)
        case txPowerPicker:
            viewModel.txPowerPickerDidSelectRow(row)
        default:
            break
        }
    }
}
