//
//  StackViewWrapper.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

// MARK: - Sesame2SettingView (Protocol)
protocol Sesame2SettingView: UIView {
    typealias Action = (_ sender: Any)->Void
    var title: String { set get }
    var value: String { set get }
}

extension Sesame2SettingView {
    @discardableResult
    fileprivate func constraintFulfill(view: UIView) -> [NSLayoutConstraint] {
        [view.autoPinBottom(),
        view.autoPinTop(),
        view.autoPinLeading(constant: 16),
        view.autoPinTrailing(constant: -16)]
    }
    
    fileprivate var contentHeightConstant: CGFloat { 50 }
}

// MARK: - Sesame2SettingViewGenerator (Concrete)
enum Sesame2SettingViewGenerator {
    static func plain(_ action: Sesame2SettingView.Action? = nil) -> Sesame2PlainSettingView {
        Sesame2PlainSettingView(action)
    }
    
    static func arrow(_ action: Sesame2SettingView.Action? = nil) -> Sesame2ArrowSettingView {
        Sesame2ArrowSettingView(action)
    }
    
    static func expandable(_ action: Sesame2SettingView.Action? = nil) -> Sesame2ExpandableSettingView {
        Sesame2ExpandableSettingView(action)
    }
    
    static func togglePicker(_ action: Sesame2SettingView.Action? = nil) -> Sesame2TogglePickerSettingView {
        Sesame2TogglePickerSettingView(action)
    }
    
    static func toggle(_ action: Sesame2SettingView.Action? = nil) -> Sesame2ToggleSettingView {
        Sesame2ToggleSettingView(action)
    }
    
    static func callToAction(_ action: Sesame2SettingView.Action? = nil) -> Sesame2SettingCallToActionView {
        Sesame2SettingCallToActionView(action)
    }
    
    static func seperatorWithStyle(_ style: Sesame2SettingSeperatorView.Style) -> Sesame2SettingSeperatorView {
        Sesame2SettingSeperatorView(style: style)
    }
}

// MARK: - Sesame2PlainSettingView (Concrete)
final class Sesame2PlainSettingView: UIView, Sesame2SettingView {
    
    var title: String {
        set {
            titleLabel.text = newValue
        }
        get {
            titleLabel.text ?? ""
        }
    }
    
    var value: String {
        set {
            valueLabel.text = newValue
        }
        get {
            valueLabel.text ?? ""
        }
    }
    
    private let containerView = UIStackView()
    private let contentView = UIStackView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let button = UIButton(type: .custom)
    private var action: Action?
    
    init(_ action: Action? = nil) {
        super.init(frame: .zero)
        self.action = action
        addSubview(containerView)
        addSubview(button)
        
        containerView.axis = .vertical
        contentView.axis = .horizontal
        
        containerView.addArrangedSubview(contentView)
        contentView.addArrangedSubview(titleLabel)
        contentView.addArrangedSubview(valueLabel)
        
        contentView.spacing = 5
        
        titleLabel.textAlignment = .left
        valueLabel.textAlignment = .right
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.numberOfLines = 1
        valueLabel.minimumScaleFactor = 0.1
        
        backgroundColor = .white
        
        autoLayoutHeight(contentHeightConstant)
        constraintFulfill(view: containerView)
        constraintFulfill(view: button)
        
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        action?(sender)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Sesame2ExpandableSettingView (Concrete)
final class Sesame2ExpandableSettingView: UIView, Sesame2SettingView {
    private let containerView = UIStackView()
    private let contentView = UIStackView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let button = UIButton(type: .custom)
    let pickerView = UIPickerView(frame: .zero)
    private var pickerViewHeightConstant: CGFloat = 216
    var isPickerOn: Bool = false {
        didSet {
            if isPickerOn {
                unfold()
            } else {
                fold()
            }
        }
    }
    private var viewHeightConstraint: NSLayoutConstraint!
    private var pickerViewHeightConstraint: NSLayoutConstraint!
    
    var title: String {
        set {
            titleLabel.text = newValue
        }
        get {
            titleLabel.text ?? ""
        }
    }
    
    var value: String {
        set {
            valueLabel.text = newValue
        }
        get {
            valueLabel.text ?? ""
        }
    }
    
    private var action: Action?
    
    init(_ action: Action? = nil) {
        super.init(frame: .zero)
        addSubview(containerView)
        self.action = action

        containerView.axis = .vertical
        contentView.axis = .horizontal
        
        containerView.addArrangedSubview(contentView)
        contentView.addArrangedSubview(titleLabel)
        contentView.addArrangedSubview(valueLabel)
        containerView.addArrangedSubview(pickerView)
        addSubview(button)
        
        contentView.spacing = 5
        
        titleLabel.textAlignment = .left
        valueLabel.textAlignment = .right
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.numberOfLines = 1
        valueLabel.minimumScaleFactor = 0.1
        
        backgroundColor = .white
        
        viewHeightConstraint = autoLayoutHeight(contentHeightConstant + pickerViewHeightConstant)
        pickerViewHeightConstraint = pickerView.autoLayoutHeight(pickerViewHeightConstant)
        
        button.autoPinTopToSafeArea(false, constant: 0)
        button.autoPinWidth()
        button.autoLayoutHeight(contentHeightConstant)
        
        constraintFulfill(view: containerView)

        isPickerOn = false
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        isPickerOn.toggle()
        action?(sender)
    }
    
    func fold() {
        pickerView.isHidden = true
        pickerViewHeightConstraint.constant = 0
        viewHeightConstraint.constant = contentHeightConstant
        layoutIfNeeded()
    }
    
    func unfold() {
        pickerView.isHidden = false
        pickerViewHeightConstraint.constant = pickerViewHeightConstant
        viewHeightConstraint.constant = contentHeightConstant + pickerViewHeightConstant
        layoutIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Sesame2ArrowSettingView (Concrete)
final class Sesame2ArrowSettingView: UIView, Sesame2SettingView {
    private let arrowImageView = UIImageView(image: UIImage.SVGImage(named: "arrow")!)
    private let containerView = UIStackView()
    private let contentView = UIStackView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let button = UIButton(type: .custom)
    
    var title: String {
        set {
            titleLabel.text = newValue
        }
        get {
            titleLabel.text ?? ""
        }
    }
    
    var value: String {
        set {
            valueLabel.text = newValue
        }
        get {
            valueLabel.text ?? ""
        }
    }
    
    private var action: Action?
    
    init(_ action: Action? = nil) {
        super.init(frame: .zero)
        self.action = action
        addSubview(containerView)
        addSubview(button)

        let tempView = UIView(frame: .zero)
        tempView.addSubview(arrowImageView)
        tempView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.axis = .vertical
        contentView.axis = .horizontal
        
        containerView.addArrangedSubview(contentView)
        contentView.addArrangedSubview(titleLabel)
        contentView.addArrangedSubview(valueLabel)
        contentView.addArrangedSubview(tempView)
        
        contentView.spacing = 5
        
        titleLabel.textAlignment = .left
        valueLabel.textAlignment = .right
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.numberOfLines = 1
        valueLabel.minimumScaleFactor = 0.1
        
        backgroundColor = .white
        
        arrowImageView.autoPinTrailing()
        arrowImageView.autoPinCenterY()
        arrowImageView.autoLayoutHeight(20)
        arrowImageView.autoLayoutWidth(20)
        autoLayoutHeight(contentHeightConstant)
        constraintFulfill(view: containerView)
        constraintFulfill(view: button)
        
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        action?(sender)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Sesame2ToggleSettingView (Concrete)
final class Sesame2ToggleSettingView: UIView, Sesame2SettingView {
    let switchView = UISwitch(frame: .zero)
    private let containerView = UIStackView()
    private let contentView = UIStackView()
    private let titleLabel = UILabel()
    
    var title: String {
        set {
            titleLabel.text = newValue
        }
        get {
            titleLabel.text ?? ""
        }
    }
    
    var value: String = ""
    
    private var action: Action?
    
    init(_ action: Action? = nil) {
        super.init(frame: .zero)
        addSubview(containerView)
        self.action = action
        
        let tempView = UIView(frame: .zero)
        tempView.addSubview(switchView)
        tempView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.axis = .vertical
        contentView.axis = .horizontal
        
        containerView.addArrangedSubview(contentView)
        contentView.addArrangedSubview(titleLabel)
        contentView.addArrangedSubview(tempView)
        
        contentView.spacing = 5
        
        titleLabel.textAlignment = .left
        
        backgroundColor = .white
        switchView.onTintColor = .sesame2Green
        
        switchView.autoPinTrailing()
        switchView.autoPinCenterY()
        autoLayoutHeight(contentHeightConstant)
        constraintFulfill(view: containerView)
        
        switchView.addTarget(self, action: #selector(toggleTapped(_:)), for: .valueChanged)
    }
    
    @objc func toggleTapped(_ sender: UISwitch) {
        action?(sender)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Sesame2TogglePickerSettingView (Concrete)
final class Sesame2TogglePickerSettingView: UIView, Sesame2SettingView {
    let switchView = UISwitch(frame: .zero)
    private let containerView = UIStackView()
    private let contentView = UIStackView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    let pickerView = UIPickerView(frame: .zero)
    let button = UIButton(type: .custom)
    private var pickerViewHeightConstant: CGFloat = 216
    
    private var viewHeightConstraint: NSLayoutConstraint!
    private var pickerViewHeightConstraint: NSLayoutConstraint!
    
    var title: String {
        set {
            titleLabel.text = newValue
        }
        get {
            titleLabel.text ?? ""
        }
    }
    
    var value: String {
        set {
            valueLabel.text = newValue
        }
        get {
            valueLabel.text ?? ""
        }
    }
    
    private var action: Action?
    
    init(_ action: Action? = nil) {
        super.init(frame: .zero)
        addSubview(containerView)
        self.action = action
        
        switchView.onTintColor = .sesame2Green
        let tempView = UIView(frame: .zero)
        tempView.addSubview(switchView)
        tempView.translatesAutoresizingMaskIntoConstraints = false
        
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false
        
        containerView.axis = .vertical
        contentView.axis = .horizontal
        
        containerView.addArrangedSubview(contentView)
        contentView.addArrangedSubview(titleLabel)
        contentView.addArrangedSubview(valueLabel)
        contentView.addArrangedSubview(tempView)
        containerView.addArrangedSubview(pickerView)
        addSubview(button)
        
        contentView.spacing = 5
        
        titleLabel.textAlignment = .left
        valueLabel.textAlignment = .right
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.numberOfLines = 1
        valueLabel.minimumScaleFactor = 0.1
        
        backgroundColor = .white
        
        viewHeightConstraint = autoLayoutHeight(contentHeightConstant + pickerViewHeightConstant)
        pickerViewHeightConstraint = pickerView.autoLayoutHeight(pickerViewHeightConstant)
        button.autoPinTop()
        button.autoPinLeading()
        button.autoPinTrailing(constant: -80)
        button.autoLayoutHeight(contentHeightConstant)
        switchView.autoPinTrailing()
        switchView.autoPinCenterY()
        constraintFulfill(view: containerView)
        
        pickerView.isHidden = !switchView.isOn
        
        switchView.addTarget(self, action: #selector(toggleTapped(_:)), for: .valueChanged)
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        fold()
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        if switchView.isOn, pickerView.isHidden == false {
            fold()
        } else if switchView.isOn, pickerView.isHidden == true {
            unfold()
        } else if pickerView.isHidden == true {
            unfold()
        } else if pickerView.isHidden == false {
            fold()
        }
        action?(sender)
    }
    
    @objc func toggleTapped(_ sender: UISwitch) {
        if sender.isOn {
            unfold()
        } else {
            fold()
        }
        action?(sender)
    }
    
    func fold() {
        pickerView.isHidden = true
        pickerViewHeightConstraint.constant = 0
        viewHeightConstraint.constant = contentHeightConstant
        layoutIfNeeded()
    }
    
    func unfold() {
        pickerView.isHidden = false
        pickerViewHeightConstraint.constant = pickerViewHeightConstant
        viewHeightConstraint.constant = contentHeightConstant + pickerViewHeightConstant
        layoutIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Sesame2SettingCallToActionView (Concrete)
final class Sesame2SettingCallToActionView: UIView, Sesame2SettingView {
    var value: String = ""
    
    private let button = UIButton(type: .custom)
    private let titleLabel = UILabel()
    var title: String {
        set {
            titleLabel.text = newValue
        }
        get {
            titleLabel.text ?? ""
        }
    }
    
    private var action: Action?
    
    init(textColor: UIColor = .black, _ action: Action? = nil) {
        super.init(frame: .zero)
        self.action = action
        
        titleLabel.textColor = textColor
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 15)
        
        backgroundColor = .white
        
        addSubview(titleLabel)
        addSubview(button)
        
        autoLayoutHeight(contentHeightConstant)
        constraintFulfill(view: titleLabel)
        constraintFulfill(view: button)
        
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        action?(sender)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Sesame2SettingSeperatorView
final class Sesame2SettingSeperatorView: UIView {
    enum Style {
        case thick
        case thin
    }
    
    private let seperatorView = UIView()
    
    init(style: Style) {
        super.init(frame: .zero)
        let seperatorHeight: CGFloat = (style == .thick) ? 8 : 1
        let padding: CGFloat = (style == .thick) ? 0 : 16

        addSubview(seperatorView)
        
        backgroundColor = .white
        seperatorView.backgroundColor = .sesame2Gray
        
        autoLayoutHeight(seperatorHeight)
        seperatorView.autoPinLeading(constant: padding)
        seperatorView.autoPinTrailing()
        seperatorView.autoPinTop()
        seperatorView.autoPinBottom()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
