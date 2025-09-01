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
    
    static func arrowExpandable(_ action: CHUIView.Action? = nil) -> CHUIExpandableArrowSettingView {
        CHUIExpandableArrowSettingView(action)
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
    
    static func slider(defaultValue: Float, maximumValue: Float, minimumValue: Float, contentWidth: CGFloat, _ action: CHUIView.Action? = nil,_ touchEndAction: CHUIView.Action? = nil) -> CHUISliderSettingView {
        CHUISliderSettingView(defaultValue: defaultValue, maximumValue: maximumValue, minimumValue: minimumValue, contentWidth: contentWidth, action: action,touchEndAction: touchEndAction)
    }
    
    @discardableResult
    static func label(_ text: String = "",
                      _ textColor: UIColor = UIColor.placeHolderColor, 
                      _ lines: Int = 0, 
                      _ lineBreakMode: NSLineBreakMode = .byWordWrapping,
                      superTuple: (view: UIView, edgeInsets: UIEdgeInsets)?) -> UILabel {
        let label = UILabel.label(text, textColor, lines, lineBreakMode)
        if let viewT = superTuple {
            viewT.view.addSubview(label)
            label.autoPinLeading(constant: viewT.edgeInsets.left)
            label.autoPinTrailing(constant: viewT.edgeInsets.right)
            label.autoPinTop(constant: viewT.edgeInsets.top)
            label.autoPinBottom(constant: viewT.edgeInsets.bottom)
        }
        return label
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
    private let plusLabel = UILabel() // "+" 标签
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
        contentView.addArrangedSubview(plusLabel)

        exclamation.autoLayoutWidth(20)
        exclamation.autoLayoutHeight(20).priority = .required - 1
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
        
        // 配置 plusLabel
        plusLabel.text = "+"
        plusLabel.textAlignment = .center
        plusLabel.textColor = .black
        plusLabel.font = UIFont.systemFont(ofSize: 24)
        plusLabel.isHidden = true // 默认隐藏
        plusLabel.setContentHuggingPriority(.required, for: .horizontal)
        plusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        containerView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 6)
        containerView.isLayoutMarginsRelativeArrangement = true
        
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
    
    func hidePlusLable(_ hide: Bool) {
        plusLabel.isHidden = hide
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
        
        tempView.autoPinTrailing().priority = .required - 2
        tempView.autoLayoutWidth(20)
        
        if let _ = addtionalIcon {
            contentView.addArrangedSubview(tempView2)
            tempView2.autoPinTrailing().priority = .required - 1
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

// MARK: - Bubble Indicator View
final class SliderBubbleView: UIView {
    private let label = UILabel()
    private let bubbleLayer = CAShapeLayer()
    
    var text: String = "" {
        didSet {
            label.text = text
            setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        backgroundColor = .clear
        
        // 设置气泡层
        bubbleLayer.fillColor = UIColor.lockGreen.cgColor
        bubbleLayer.strokeColor = UIColor.clear.cgColor
        layer.addSublayer(bubbleLayer)
        
        // 设置标签
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 1  // 确保单行显示
        label.adjustsFontSizeToFitWidth = true  // 自动调整字体大小以适应宽度
        label.minimumScaleFactor = 0.75  // 最小缩放比例
        addSubview(label)
        
        // 布局约束
        label.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 更新标签尺寸
        label.sizeToFit()
        let labelSize = label.bounds.size
        
        // 气泡路径（圆角矩形带小三角）
        let bubbleWidth = max(labelSize.width + 24, 80)
        let bubbleHeight = labelSize.height + 16
        let bubbleRect = CGRect(
            x: bounds.midX - bubbleWidth/2,
            y: 0,
            width: bubbleWidth,
            height: bubbleHeight
        )
        
        // 绘制圆角矩形
        let cornerRadius: CGFloat = 8
        let bubblePath = UIBezierPath(roundedRect: bubbleRect, cornerRadius: cornerRadius)
        
        // 添加底部三角形
        let triangleSize: CGFloat = 8
        bubblePath.move(to: CGPoint(x: bounds.midX - triangleSize, y: bubbleHeight))
        bubblePath.addLine(to: CGPoint(x: bounds.midX, y: bubbleHeight + triangleSize))
        bubblePath.addLine(to: CGPoint(x: bounds.midX + triangleSize, y: bubbleHeight))
        bubblePath.close()
        
        bubbleLayer.path = bubblePath.cgPath
        
        // 更新自身尺寸
        let newSize = CGSize(width: bubbleWidth, height: bubbleHeight + triangleSize)
        if bounds.size != newSize {
            frame.size = newSize
        }
        
        // 重新设置标签约束，确保居中
        label.frame = CGRect(
            x: bubbleRect.minX + 12,  // 左右各留12点边距
            y: bubbleRect.minY + 8,   // 上下各留8点边距
            width: bubbleRect.width - 24,
            height: bubbleRect.height - 16
        )
    }
}

// MARK: - Sesame2SliderSettingView (Concrete)
final class CHUISliderSettingView: UIView, CHUIView {
    let slider = UISlider(frame: .zero)
    private let bubbleView = SliderBubbleView(frame: .zero)
    private let containerView = UIStackView()
    private let contentView = UIStackView()
    private let iconImageView = UIImageView()
    private let titleStackView = UIStackView()
    private let sliderContainerView = UIView()
    
    var title: String {
        set {
            titleLabel.text = newValue
            titleWidth.constant = titleLabel.intrinsicContentSize.width
        }
        get {
            titleLabel.text ?? ""
        }
    }
    var icon: UIImage? {
        get {
            return iconImageView.image
        }
        set {
            iconImageView.image = newValue
            iconImageView.isHidden = (newValue == nil)
        }
    }
    var isSliderHidden: Bool {
        get {
            return sliderContainerView.isHidden
        }
        set {
            sliderContainerView.isHidden = newValue
        }
    }
    
    var value = ""
    
    private var action: Action?
    private var touchEndAction: Action?
    private let titleLabel = UILabel()
    private var titleWidth: NSLayoutConstraint!
    
    init(defaultValue: Float, maximumValue: Float, minimumValue: Float, contentWidth: CGFloat = 200, action: Action? = nil, touchEndAction: Action? = nil) {
        super.init(frame: .zero)
        addSubview(containerView)
        self.action = action
        self.touchEndAction = touchEndAction
        
        addSubview(bubbleView)
        bubbleView.isHidden = true
        
        // 设置图标视图
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.isHidden = true // 默认隐藏
        
        // 调整图标尺寸 - 增大尺寸
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 35),  // 增大宽度
            iconImageView.heightAnchor.constraint(equalToConstant: 35)  // 增大高度
        ])
        
        // 创建标题和图标的堆栈视图
        titleStackView.axis = .horizontal
        titleStackView.spacing = 8  // 减小间距，使图标更靠近文本
        titleStackView.alignment = .center
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(iconImageView)
        
        // 配置滑块容器
        sliderContainerView.translatesAutoresizingMaskIntoConstraints = false
        slider.translatesAutoresizingMaskIntoConstraints = false
        sliderContainerView.addSubview(slider)
        
        // 添加滑块的宽度约束
        slider.widthAnchor.constraint(equalToConstant: contentWidth).isActive = true
        
        // 将滑块在容器中居中，但偏右
        slider.centerYAnchor.constraint(equalTo: sliderContainerView.centerYAnchor).isActive = true
        
        // 修改水平位置，使滑块靠右
        slider.trailingAnchor.constraint(equalTo: sliderContainerView.trailingAnchor, constant: -20).isActive = true  // 右边距20
        
        // 设置滑块容器的尺寸约束
        sliderContainerView.heightAnchor.constraint(equalTo: slider.heightAnchor).isActive = true
        sliderContainerView.widthAnchor.constraint(equalTo: slider.widthAnchor, constant: 40).isActive = true  // 增加容器宽度以容纳右边距
        
        containerView.axis = .vertical
        contentView.axis = .horizontal
        
        // 调整内容视图布局
        contentView.alignment = .center  // 确保垂直居中对齐
        contentView.distribution = .fill  // 允许视图根据内容调整大小
        
        containerView.addArrangedSubview(contentView)
        contentView.addArrangedSubview(titleStackView)
        
        // 添加弹性空间，使滑块靠右
        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        contentView.addArrangedSubview(spacerView)
        
        contentView.addArrangedSubview(sliderContainerView)
        
        contentView.spacing = 8  // 增加间距
        
        titleLabel.textAlignment = .left
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 2
        titleLabel.minimumScaleFactor = 0.1
        titleWidth = titleLabel.autoLayoutWidth(titleLabel.intrinsicContentSize.width)
        
        backgroundColor = .white
        constraintFulfill(view: containerView)
        
        slider.addTarget(self, action: #selector(sliderTouchBegan(_:)), for: .touchDown)
        slider.addTarget(self, action: #selector(valueChanged(_:forEvent:)), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderTouchEnded(_:forEvent:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        slider.maximumValue = maximumValue
        slider.minimumValue = minimumValue
        slider.value = defaultValue
        
        autoLayoutHeight(contentHeightConstant)
    }
    
    func updateBubble(withValue value: String) {
        bubbleView.text = value
        updateBubblePosition(slider: slider)
    }
    
    func updateBubblePosition(slider: UISlider) {
        // 计算气泡位置
        let sliderFrame = slider.convert(slider.bounds, to: self)
        let thumbRect = slider.thumbRect(forBounds: slider.bounds, trackRect: slider.trackRect(forBounds: slider.bounds), value: slider.value)
        let thumbCenterX = sliderFrame.minX + thumbRect.midX
        
        // 更新气泡位置
        bubbleView.center = CGPoint(x: thumbCenterX, y: sliderFrame.minY - bubbleView.frame.height/2 - 5)
    }
    
    @objc func sliderTouchBegan(_ sender: UISlider) {
        bubbleView.isHidden = false
    }
    
    @objc func valueChanged(_ sender: UISlider, forEvent event: UIEvent) {
        updateBubblePosition(slider: sender)
        action?(sender, event)
    }
    
    @objc func sliderTouchEnded(_ sender: UISlider, forEvent event: UIEvent) {
        bubbleView.isHidden = true
        touchEndAction?(sender, event)
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
    var heightConstraint: NSLayoutConstraint?
    
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
        
        heightConstraint = autoLayoutHeight(contentHeightConstant)
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

// MARK: - CHUIExpandableArrowSettingView (Concrete)
final class CHUIExpandableArrowSettingView: UIView, CHUIView {
    private let containerView = UIStackView()
    private let contentView = UIStackView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let button = UIButton(type: .custom)
    let pickerView = UIPickerView(frame: .zero)
    private let arrowImageView = UIImageView(image: UIImage.SVGImage(named: "arrow")!)
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
        
        contentView.spacing = 0
        
        titleLabel.textAlignment = .left
        valueLabel.textAlignment = .left
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.numberOfLines = 1
        valueLabel.minimumScaleFactor = 0.1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.numberOfLines = 1
        titleLabel.minimumScaleFactor = 0.1
        titleLabel.autoPinWidthLessThanOrEqual(valueLabel)

        let tempView = UIView(frame: .zero)
        tempView.contentMode = .center
        tempView.addSubview(arrowImageView)
        arrowImageView.autoPinCenterY()
        arrowImageView.autoPinCenterX()
        tempView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addArrangedSubview(tempView)
        tempView.autoPinTrailing().priority = .required - 2
        tempView.autoLayoutWidth(40)
        arrowImageView.isUserInteractionEnabled = true
        tempView.isUserInteractionEnabled = true
        tempView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onArrowTapped( _:))))

        backgroundColor = .white
        
        viewHeightConstraint = autoLayoutHeight(contentHeightConstant + pickerViewHeightConstant)
        pickerViewHeightConstraint = pickerView.autoLayoutHeight(pickerViewHeightConstant)
        
        button.autoPinTopToSafeArea(false, constant: 0)
        button.autoPinWidth()
        button.autoLayoutHeight(contentHeightConstant)
        
        constraintFulfill(view: containerView)

        isPickerOn = false
        button.addTarget(self, action: #selector(onButtonTapped(_:)), for: .touchUpInside)
    }
    
    @objc func onButtonTapped(_ sender: UIButton) {
        if pickerView.isHidden == true {
            unfold()
        } else if pickerView.isHidden == false {
            fold()
        }
        action?(sender,nil)
    }
    
    @objc func onArrowTapped(_ sender: UIGestureRecognizer) {
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
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if valueLabel.bounds.contains(self.convert(point, to: valueLabel))
            || titleLabel.bounds.contains(self.convert(point, to: titleLabel)) {
            return button.hitTest(point, with: event)
        }
        if pickerView.isHidden == false, pickerView.frame.contains(point) {
            return pickerView.hitTest(point, with: event)
        }
        
        if let arrow = arrowImageView.superview, arrow.bounds.contains(self.convert(point, to: arrow)) {
            if pickerView.isHidden {
                return arrow
            }
            return button.hitTest(point, with: event)
        }
        return superview?.hitTest(point, with: event)
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
    
    init(style: Style,separatorViewBackgroundColor: UIColor = .sesame2Gray) {
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
        seperatorView.backgroundColor = separatorViewBackgroundColor
        
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

// MARK: - Label
extension UILabel {
    static func label(_ text: String = "",
                      _ textColor: UIColor = UIColor.placeHolderColor,
                      _ lines: Int = 0,
                      _ lineBreakMode: NSLineBreakMode = .byWordWrapping) -> UILabel {
        let label = UILabel(frame: .zero)
        label.text = text
        label.textColor = textColor
        label.numberOfLines = lines
        label.lineBreakMode = lineBreakMode
        return label
    }
}
