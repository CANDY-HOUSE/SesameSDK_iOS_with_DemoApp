//
//  PickerProxy.swift
//  SesameUI
//  simple picker 數據源及選中處理代理器
//  Created by eddy on 2023/12/14.
//  Copyright © 2023 CandyHouse. All rights reserved.
//

import Foundation
import UIKit
import SesameSDK

public protocol PickerItemDiscriptor {
    var displayName: String { get }
    var selectHandler: ((PickerItemDiscriptor) -> Void)? { get set }
}

final class PickerProxy<T: PickerItemDiscriptor>: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {

    var items: [T] = [T]()
    
    init(items: [T]) {
        self.items = items
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { return items.count }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel = view as? UILabel
        if pickerLabel == nil {
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.systemFont(ofSize: 16)
            pickerLabel?.textAlignment = .center
        }
        pickerLabel?.text = items[row].displayName
        return pickerLabel!
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        items[row].selectHandler?(items[row])
    }
    
    deinit {
        L.d("deinit")
    }
}
