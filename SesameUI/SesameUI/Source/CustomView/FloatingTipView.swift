//
//  FloatingTooltipView.swift
//  SesameUI
//
//  Created by eddy on 2024/4/22.
//  Copyright © 2024 CandyHouse. All rights reserved.
//

import UIKit

enum FloatingTipViewStyle {
    case imageText(gifImagePathName: String, text: String)
    case textOnly(text: String)
    case topImageWithText(imageName: String, text: String)
}

class FloatingTipView: UIView {
    
    private var style: FloatingTipViewStyle
    private var layout: NSLayoutConstraint!
    
    private let label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.placeHolderColor
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.numberOfLines = 0 //允許換行
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .left
        return label
    }()
    
    private var layoutGuide = (spacing: 16.0, maxHeight: 500.0, gifWidth: 100.0)
    
    private let gifImageView: GIFImageView = {
        let lottie = GIFImageView(frame: .zero)
        lottie.contentMode = .scaleAspectFit
        return lottie
    }()
    
    private let topImageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.isHidden = true
        return view
    }()
    
    private let topImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    var FloatingHeight: CGFloat {
        get {
            layoutIfNeeded()
            switch style {
            case .textOnly(_):
                return min(CGRectGetMaxY(label.frame) + layoutGuide.spacing, layoutGuide.maxHeight)
            case .topImageWithText(_, _):
                return CGRectGetMaxY(label.frame)
            default:
                return min(max(CGRectGetMaxY(label.frame), CGRectGetMaxY(gifImageView.frame)) + layoutGuide.spacing, layoutGuide.maxHeight)
            }
        }
    }
    
    init(style: FloatingTipViewStyle) {
        self.style = style
        super.init(frame: .zero)
        
        backgroundColor = .sesameBackgroundColor
        setupSubviews()
        configure(with: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @discardableResult
    class func showIn(superView: UIView, style: FloatingTipViewStyle) -> FloatingTipView {
        let floatingView = FloatingTipView(style: style)
        superView.addSubview(floatingView)
        floatingView.autoPinTopToSafeArea()
        floatingView.autoPinLeading()
        floatingView.autoPinTrailing()
        return floatingView
    }
    
    private func setupSubviews() {
        switch style {
        case .imageText(_, _), .textOnly(_):
            addSubview(gifImageView)
            addSubview(label)
            
        case .topImageWithText(_, _):
            addSubview(topImageContainerView)
            topImageContainerView.addSubview(topImageView)
            addSubview(label)
        }
        
        switch style {
        case .imageText(_, _):
            gifImageView.autoPinLeading(constant: layoutGuide.spacing * 0.5)
            gifImageView.autoLayoutWidth(layoutGuide.gifWidth)
            gifImageView.autoPinTop(constant: layoutGuide.spacing)
            gifImageView.autoLayoutHeight(layoutGuide.gifWidth * 1.5)
            autoEqualHeightTo(gifImageView, 2 * layoutGuide.spacing)
            
            let gifLayout = label.autoPinLeadingToTrailingOfView(gifImageView, constant: layoutGuide.spacing)
            gifLayout.priority = .required - 1
            let toSupper = label.autoPinLeading(constant: layoutGuide.spacing * 0.5)
            layout = toSupper
            toSupper.priority = .defaultLow
            label.autoPinTrailing(constant: layoutGuide.spacing * -0.5)
            label.autoPinTop(constant: layoutGuide.spacing)
            label.autoPinBottom(constant: -layoutGuide.spacing)
            
        case .textOnly(_):
            let toSupper = label.autoPinLeading(constant: layoutGuide.spacing * 0.5)
            layout = toSupper
            label.autoPinTrailing(constant: layoutGuide.spacing * -0.5)
            label.autoPinTop(constant: layoutGuide.spacing)
            label.autoPinBottom(constant: -layoutGuide.spacing)
            
        case .topImageWithText(_, _):
            topImageContainerView.autoPinTop()
            topImageContainerView.autoPinLeading()
            topImageContainerView.autoPinTrailing()
            
            // 图片视图 - 固定300pt大小，居中显示，无上下边距
            topImageView.autoPinCenterX()  // 水平居中
            topImageView.autoPinTop()      // 紧贴顶部，无边距
            topImageView.autoPinBottom()   // 紧贴底部，无边距
            topImageView.autoLayoutWidth(300)  // 固定宽度300pt
            topImageView.autoLayoutHeight(300) // 固定高度300pt
            
            // 文字标签 - 充满屏幕宽度，无上下边距
            label.autoPinTopToBottomOfView(topImageContainerView)  // 紧贴图片底部
            label.autoPinLeading()   // 无边距，充满屏幕
            label.autoPinTrailing()  // 无边距，充满屏幕
            label.autoPinBottom()    // 紧贴底部，无边距
            
            label.backgroundColor = .sesameBackgroundColor
        }
    }
    
    private func configure(with style: FloatingTipViewStyle) {
        switch style {
        case .imageText(let gifImage, let text):
            label.text = text
            gifImageView.isHidden = false
            topImageContainerView.isHidden = true
            gifImageView.prepareForAnimation(withGIFNamed: gifImage) { [weak self] in
                self?.gifImageView.startAnimatingGIF()
            }
            
        case .textOnly(let text):
            label.text = text
            layout?.priority = .required
            gifImageView.isHidden = true
            topImageContainerView.isHidden = true
            
        case .topImageWithText(let imageName, let text):
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left  // 左对齐
            paragraphStyle.firstLineHeadIndent = layoutGuide.spacing
            paragraphStyle.headIndent = layoutGuide.spacing
            paragraphStyle.tailIndent = -layoutGuide.spacing
            
            let attributedText = NSAttributedString(
                string: "\n" + text + "\n",  // 添加换行符实现上下内边距
                attributes: [
                    .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                    .foregroundColor: UIColor.placeHolderColor,
                    .paragraphStyle: paragraphStyle
                ]
            )
            
            label.attributedText = attributedText
            label.numberOfLines = 0
            
            gifImageView.isHidden = true
            topImageContainerView.isHidden = false
            
            backgroundColor = .white
            
            topImageView.image = UIImage(named: imageName)
            
            // 设置图片容器高度 = 300（无上下边距）
            topImageContainerView.autoLayoutHeight(300)
        }
    }
    
    deinit {
        gifImageView.stopAnimatingGIF()
        gifImageView.removeFromSuperview()
    }
}
