//
//  PickerController.swift
//  SesameUI
//
//  Created by eddy on 2024/1/17.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

class PickerController<T: PickerItemDiscriptor>: UIViewController {
    private var doneButtonTapAction: (() -> Void)!
    let pickerView = UIPickerView()
    private var items: [T] = [T]()
    lazy var pickerProxy = {
        return PickerProxy(items: self.items)
    }()
    lazy var toolbar = {
        let toolBarView = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        let leftButton = UIBarButtonItem(title: "co.candyhouse.sesame2.Cancel".localized, style: .plain, target: self, action: #selector(onCancelButtonTapped))
        let rightButton = UIBarButtonItem(title: "co.candyhouse.sesame2.OK".localized, style: .plain, target: self, action: #selector(onDoneButtonTapped))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBarView.tintColor = .black
        toolBarView.barTintColor = .white
        toolBarView.setShadowImage(UIImage(), forToolbarPosition: UIBarPosition.any)
        toolBarView.backgroundColor = .white
//        toolBarView.translatesAutoresizingMaskIntoConstraints = false
        toolBarView.setItems([leftButton, flexibleSpace, rightButton], animated: false)
        return toolBarView
    }()
    private var showToolbar = true
 
    @objc func onCancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc func onDoneButtonTapped() {
        doneButtonTapAction()
        dismiss(animated: true)
    }
    
    init(items: [T], isShowToolbar: Bool = true, doneHandler: @escaping () -> Void) {
        super.init(nibName: nil, bundle: nil)
        self.items = items
        self.showToolbar = isShowToolbar
        self.doneButtonTapAction = doneHandler
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.backgroundColor = UIColor(white: 0, alpha: 0.3)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.backgroundColor = UIColor(white: 1, alpha: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(pickerView)
        pickerView.backgroundColor = .white
        pickerView.delegate = pickerProxy
        pickerView.dataSource = pickerProxy
        pickerView.autoPinBottom()
        pickerView.autoPinLeading()
        pickerView.autoPinTrailing()
        pickerView.autoLayoutHeight(250)
        
        if showToolbar {
            view.addSubview(toolbar)
            toolbar.autoPinLeading()
            toolbar.autoPinTrailing()
            toolbar.autoPinWidth()
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                toolbar.bottomAnchor.constraint(equalTo: pickerView.topAnchor)
            ])
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard showToolbar == false else { return }
        onDoneButtonTapped()
    }
}
