//
//  CHUIView.swift
//  SesameUI
//  [設定頁自訂UI組件]
//  Created by Wayne Hsiao on 2020/9/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

// MARK: - Sesame2SettingView (Protocol)
protocol CHUIView: UIView {
    typealias Action = (_ sender: Any, _ event: UIEvent?)->Void
    var title: String { set get }
    var value: String { set get }
}

extension CHUIView {
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
enum CHUIViewGenerator {
    static func plain(_ action: CHUIView.Action? = nil) -> CHUIPlainSettingView {
        CHUIPlainSettingView(action)
    }
    
    static func arrow(addtionalIcon: String? = nil, _ action: CHUIView.Action? = nil) -> CHUIArrowSettingView {
        CHUIArrowSettingView(addtionalIcon: addtionalIcon, action)
    }
    
    static func expandable(_ action: CHUIView.Action? = nil) -> CHUIExpandableSettingView {
        CHUIExpandableSettingView(action)
    }
    
    static func togglePicker(_ action: CHUIView.Action? = nil) -> CHUITogglePickerSettingView {
        CHUITogglePickerSettingView(action)
    }
    
    static func toggle(includeArrowImage: Bool = false, _ action: CHUIView.Action? = nil) -> CHUIToggleSettingView {
        CHUIToggleSettingView(includeArrowImage: includeArrowImage, action)
    }
    
    static func picker(_ action: CHUIView.Action? = nil) -> CHUIPickerSettingView {
        CHUIPickerSettingView(action)
    }
    
    static func textField(style: CHUITextFieldSettingView.Style = .normal,
                          placeholder: String = "",
                          _ action: CHUIView.Action? = nil) -> CHUITextFieldSettingView {
        CHUITextFieldSettingView(style: style, placeholder: placeholder, action)
    }
    
    static func button(_ action: CHUIView.Action? = nil) -> CHUISettingButtonView {
        CHUISettingButtonView(action)
    }
    
    static func callToAction(_ action: CHUIView.Action? = nil) -> CHUICallToActionView {
        CHUICallToActionView(action)
    }
    
    static func seperatorWithStyle(_ style: CHUISeperatorView.Style) -> CHUISeperatorView {
        CHUISeperatorView(style: style)
    }
    
    static func slider(defaultValue: Float, maximumValue: Float, minimumValue: Float, _ action: CHUIView.Action? = nil) -> CHUISliderSettingView {
        CHUISliderSettingView(defaultValue: defaultValue, maximumValue: maximumValue, minimumValue: minimumValue, action)
    }
}

// MARK: - Sesame2PlainSettingView (Concrete)
final class CHUIPlainSettingView: UIView, CHUIView {
    
    var title: String {
        set {
            titleLabel.text = newValue
            titleWidth.constant = titleLabel.intrinsicContentSize.width
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
    private var titleWidth: NSLayoutConstraint!
    let exclamation = UIImageView(image: UIImage.SVGImage(named: "exclamation", fillColor: .lockRed))
    init(_ action: Action? = nil) {
        super.init(frame: .zero)
        self.action = action
        addSubview(containerView)
        addSubview(button)
        
        containerView.axis = .vertical
        contentView.axis = .horizontal
        contentView.spacing = 5
        
        containerView.addArrangedSubview(contentView)
        contentView.addArrangedSubview(titleLabel)
        contentView.addArrangedSubview(exclamation)
        contentView.addArrangedSubview(valueLabel)

        exclamation.autoLayoutWidth(20)
        exclamation.autoLayoutHeight(20)
        exclamation.autoPinCenterY()
        exclamation.contentMode = .scaleAspectFit
        exclamation.isHidden = true
        
        titleLabel.textAlignment = .left
        valueLabel.textAlignment = .right
        valueLabel.textColor = .secondaryLabelColor
        titleWidth = titleLabel.autoLayoutWidth(titleLabel.intrinsicContentSize.width)
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.numberOfLines = 1
        valueLabel.minimumScaleFactor = 0.1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabel.minimumScaleFactor = 0.1
        
        backgroundColor = .white
        
        autoLayoutHeight(contentHeightConstant)
        constraintFulfill(view: containerView)
        constraintFulfill(view: button)
        
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    }
    
    func appendViewToTitle(_ view: UIView) {
        contentView.insertArrangedSubview(view, at: 1)
    }

    @objc func buttonTapped(_ sender: UIButton) {
        action?(sender,nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setColor(_ color: UIColor) {
        titleLabel.textColor = color
    }
}

// MARK: - Sesame2ExpandableSettingView (Concrete)
final class CHUIExpandableSettingView: UIView, CHUIView {
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
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.autoPinWidthLessThanOrEqual(titleLabel)
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.numberOfLines = 1
        valueLabel.minimumScaleFactor = 0.1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabel.minimumScaleFactor = 0.1
        
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
        action?(sender,nil)
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
final class CHUIArrowSettingView: UIView, CHUIView {
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
    
    init(addtionalIcon: String? = nil, _ action: Action? = nil) {
        super.init(frame: .zero)
        self.action = action
        addSubview(containerView)
        addSubview(button)

        let tempView = UIView(frame: .zero)
        tempView.addSubview(arrowImageView)
        tempView.translatesAutoresizingMaskIntoConstraints = false
        
        let tempView2 = UIView(frame: .zero)
        var arrowImageView2: UIImageView!
        if let addtionalIcon = addtionalIcon {
            arrowImageView2 = UIImageView(image: UIImage.SVGImage(named: addtionalIcon, fillColor: .secondaryLabelColor)!)
            tempView2.addSubview(arrowImageView2)
            tempView2.translatesAutoresizingMaskIntoConstraints = false
        }
        
        containerView.axis = .vertical
        contentView.axis = .horizontal
        
        containerView.addArrangedSubview(contentView)
        contentView.addArrangedSubview(titleLabel)
        contentView.addArrangedSubview(valueLabel)
        contentView.addArrangedSubview(tempView)
        
        tempView.autoPinTrailing()
        tempView.autoLayoutWidth(20)
        
        if let _ = addtionalIcon {
            contentView.addArrangedSubview(tempView2)
            tempView2.autoPinTrailing()
        }
        
        contentView.spacing = 5
        
        titleLabel.textAlignment = .left
        valueLabel.textAlignment = .right
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.autoPinWidthLessThanOrEqual(titleLabel)
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.numberOfLines = 1
        valueLabel.minimumScaleFactor = 0.1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabel.minimumScaleFactor = 0.1
        
        backgroundColor = .white
        
        arrowImageView.autoPinTrailing()
        arrowImageView.autoPinCenterY()
        arrowImageView.autoLayoutHeight(20)
        arrowImageView.autoLayoutWidth(20)
        
        if let _ = addtionalIcon {
            arrowImageView2.autoPinTrailingToLeadingOfView(arrowImageView)
            arrowImageView2.autoPinCenterY()
            arrowImageView2.autoLayoutHeight(17)
            arrowImageView2.autoLayoutWidth(17)
        }
        
        autoLayoutHeight(contentHeightConstant)
        constraintFulfill(view: containerView)
        constraintFulfill(view: button)
        
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        action?(sender,nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Sesame2ToggleSettingView (Concrete)
final class CHUIToggleSettingView: UIView, CHUIView {
    let switchView = UISwitch(frame: .zero)
    private let containerView = UIStackView()
    private let contentView = UIStackView()
    private let titleLabel = UILabel()
    private let button = UIButton(type: .custom)
    
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
    
    init(includeArrowImage: Bool = false, _ action: Action? = nil) {
        super.init(frame: .zero)
        addSubview(containerView)
        addSubview(button)
        
        self.action = action
        
        let tempView = UIView(frame: .zero)
        tempView.addSubview(switchView)
        tempView.translatesAutoresizingMaskIntoConstraints = false

        containerView.axis = .vertical
        contentView.axis = .horizontal
        
        containerView.addArrangedSubview(contentView)
        contentView.addArrangedSubview(titleLabel)
        if includeArrowImage {
            let arrowImageView = UIImageView(image: UIImage.SVGImage(named: "arrow")!)
            arrowImageView.translatesAutoresizingMaskIntoConstraints = false
            let arrowTempView = UIView(frame: .zero)
            arrowTempView.addSubview(arrowImageView)
            arrowTempView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addArrangedSubview(tempView)
            contentView.addArrangedSubview(arrowTempView)
            arrowImageView.autoPinCenterY()
            arrowTempView.autoPinTrailing(constant:0)
            arrowImageView.autoPinTrailing(constant:0)
            arrowTempView.autoLayoutWidth(20)
            
            switchView.autoPinTrailingToLeadingOfView(arrowTempView, constant: 0)
            switchView.autoPinCenterY()
        } else {
            contentView.addArrangedSubview(tempView)
            switchView.autoPinTrailing()
            switchView.autoPinCenterY()
        }

        contentView.spacing = 5
        
        titleLabel.textAlignment = .left
        
        backgroundColor = .white
        switchView.onTintColor = .sesame2Green

        autoLayoutHeight(contentHeightConstant)
        constraintFulfill(view: containerView)
        
        switchView.addTarget(self, action: #selector(toggleTapped(_:)), for: .valueChanged)
        
        button.autoPinTop()
        button.autoPinBottom()
        button.autoPinLeading()
        button.autoPinTrailing(constant: -100)
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    }
    
    @objc func toggleTapped(_ sender: UISwitch) {
        action?(sender,nil)
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        action?(sender,nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Sesame2SliderSettingView (Concrete)
final class CHUISliderSettingView: UIView, CHUIView {
    let slider = UISlider(frame: .zero)
    private let containerView = UIStackView()
    private let contentView = UIStackView()
    var title = ""
    var value = ""
    
    private var action: Action?
    
    init(defaultValue: Float, maximumValue: Float, minimumValue: Float, _ action: Action? = nil) {
        super.init(frame: .zero)
        addSubview(containerView)
        self.action = action
        
        let tempView = UIView(frame: .zero)
        tempView.addSubview(slider)
        slider.translatesAutoresizingMaskIntoConstraints = false
        tempView.translatesAutoresizingMaskIntoConstraints = false
        
        slider.autoPinEdgesToSuperview(safeArea: true)
        
        containerView.axis = .vertical
        contentView.axis = .horizontal
        
        containerView.addArrangedSubview(contentView)
        contentView.addArrangedSubview(tempView)
        
        contentView.spacing = 5
        
        backgroundColor = .white
        constraintFulfill(view: containerView)
        
        slider.addTarget(self, action: #selector(valueChanged(_:forEvent:)), for: .valueChanged)
        slider.maximumValue = maximumValue
        slider.minimumValue = minimumValue
        slider.value = defaultValue
        
        autoLayoutHeight(contentHeightConstant)
    }
    
    @objc func valueChanged(_ sender: UISlider, forEvent event: UIEvent) {
        action?(sender,event)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Sesame2TextFieldSettingView (Concrete)
final class CHUITextFieldSettingView: UIView, CHUIView, UITextFieldDelegate {
    enum Style {
        case normal
        case big
    }
    
    let textField = UITextField(frame: .zero)
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
    
    var value: String {
        set {
            textField.text = newValue
        }
        get {
            textField.text ?? ""
        }
    }
    
    var placeHolder: String {
        set {
            textField.placeholder = newValue
        }
        get {
            textField.placeholder ?? ""
        }
    }
    
    private var action: Action?
    
    init(style: Style = .normal, placeholder: String = "", _ action: Action? = nil) {
        super.init(frame: .zero)
        addSubview(containerView)
        self.action = action
        
        let tempView = UIView(frame: .zero)
        tempView.addSubview(textField)
        tempView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.axis = .vertical
        contentView.axis = .horizontal
        
        containerView.addArrangedSubview(contentView)
        contentView.addArrangedSubview(titleLabel)
        contentView.addArrangedSubview(tempView)
        
        contentView.spacing = 5
        
        titleLabel.textAlignment = .left
        
        backgroundColor = .white
        textField.placeholder = placeholder
        textField.delegate = self
        textField.autoPinLeadingToTrailingOfView(titleLabel, constant: 5)
        textField.autoPinTrailing()
        textField.autoPinCenterY()
        
        if style == .normal {
            autoLayoutHeight(contentHeightConstant)
        } else {
            autoLayoutHeight(80)
            titleLabel.font = .boldSystemFont(ofSize: 20)
            textField.font = .systemFont(ofSize: 20)
        }
        
        constraintFulfill(view: containerView)
    }
    
    @objc func toggleTapped(_ sender: UISwitch) {
        action?(sender,nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        action?(textField,nil)
        return true
    }
}

// MARK: - Sesame2TogglePickerSettingView (Concrete)
final class CHUITogglePickerSettingView: UIView, CHUIView {
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
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.autoPinWidthLessThanOrEqual(titleLabel)
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.numberOfLines = 1
        valueLabel.minimumScaleFactor = 0.1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabel.minimumScaleFactor = 0.1
        
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
        action?(sender,nil)
    }
    
    @objc func toggleTapped(_ sender: UISwitch) {
        if sender.isOn {
            unfold()
        } else {
            fold()
        }
        action?(sender,nil)
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

// MARK: - Sesame2PickerSettingView (Concrete)
final class CHUIPickerSettingView: UIView, CHUIView {
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
        
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false
        
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
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.autoPinWidthLessThanOrEqual(titleLabel)
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.numberOfLines = 1
        valueLabel.minimumScaleFactor = 0.1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabel.minimumScaleFactor = 0.1
        
        backgroundColor = .white
        
        viewHeightConstraint = autoLayoutHeight(contentHeightConstant + pickerViewHeightConstant)
        pickerViewHeightConstraint = pickerView.autoLayoutHeight(pickerViewHeightConstant)
        button.autoPinTop()
        button.autoPinLeading()
        button.autoPinTrailing(constant: -80)
        button.autoLayoutHeight(contentHeightConstant)
        constraintFulfill(view: containerView)
        
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        fold()
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        if pickerView.isHidden == true {
            unfold()
        } else if pickerView.isHidden == false {
            fold()
        }
        action?(sender,nil)
    }
    
    @objc func toggleTapped(_ sender: UISwitch) {
        if sender.isOn {
            unfold()
        } else {
            fold()
        }
        action?(sender,nil)
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

// MARK: - Sesame2SettingButtonView (Concrete)
final class CHUISettingButtonView: UIView, CHUIView {
    
    private let containerView = UIStackView()
    private let contentView = UIStackView()
    private let button = UIButton(type: .custom)
    let titleLabel = UILabel()
    private let valueLabel = UILabel()
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
        
        titleLabel.textAlignment = .left
        valueLabel.textAlignment = .right
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.autoPinWidthLessThanOrEqual(titleLabel)
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.numberOfLines = 1
        valueLabel.minimumScaleFactor = 0.1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabel.minimumScaleFactor = 0.1
        backgroundColor = .white
        
        addSubview(button)
        
        autoLayoutHeight(contentHeightConstant)
        constraintFulfill(view: containerView)
        constraintFulfill(view: button)
        
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        action?(sender,nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Sesame2SettingCallToActionView (Concrete)
final class CHUICallToActionView: UIView, CHUIView {
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
        action?(sender,nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Sesame2SettingSeperatorView
final class CHUISeperatorView: UIView {
    enum Style {
        case thick
        case thin
        case group
    }
    
    private let seperatorView = UIView()
    
    init(style: Style) {
        super.init(frame: .zero)
        
        var seperatorHeight: CGFloat
        var padding: CGFloat
        switch style {
        case .thin:
            seperatorHeight = 1
            padding = 16
        case .thick:
            seperatorHeight = 8
            padding = 0
        case .group:
            seperatorHeight = 50
            padding = 0
        }

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
