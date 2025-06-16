//
//  UIViewController+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/12/16.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit

extension UIViewController {
    func presentCHAlertWithPlaceholder(title: String,
                                       placeholder: String,
                                       hint: String,
                                       callback: @escaping (_ newValue: String)->Void,
                                       cancelHandler: (()->Void)?=nil) {
        let myAlert = UIStoryboard.viewControllers.changeValueDialog!
        myAlert.value = placeholder
        myAlert.titleLBText = title
        myAlert.valueDescription = hint
        myAlert.callback = callback
        myAlert.cancelHandler = cancelHandler
        myAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        myAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        self.present(myAlert, animated: true, completion: nil)
    }
}

// 導航選項擴展
extension UIViewController {
    
    /// 設置右側可關閉的導航選項
    /// - Parameter selector: 觸發函數
    func setClosableNavigationRightItem(_ selector: Selector, isRight: Bool = true) {
        let dismissButton = UIButton(type: .custom)
        dismissButton.setImage(UIImage.SVGImage(named: "icons_filled_close"), for: .normal)
        let dismissButtonItem = UIBarButtonItem(customView: dismissButton)
        dismissButtonItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        dismissButtonItem.customView?.heightAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButtonItem.customView?.widthAnchor.constraint(equalToConstant: 32).isActive = true
        dismissButton.addTarget(self, action: selector, for: .touchUpInside)
        if isRight {
            navigationItem.rightBarButtonItem = dismissButtonItem
        } else {
            navigationItem.leftBarButtonItem = dismissButtonItem
        }
    }
    
    func setNavigationRightItem(_ img: UIImage, _ selector: Selector) {
        let rightButtonItem = UIBarButtonItem(image: img,
                                              style: .done,
                                              target: self,
                                              action: selector)
        navigationItem.rightBarButtonItem = rightButtonItem
    }

    
    /// 設置右側導航選擇
    /// - Parameters:
    ///   - iconName: 圖片名稱 svg 格式
    ///   - selector: 觸發函數
    func setNavigationRightItem(_ iconName: String, _ selector: Selector) {
        let rightButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: iconName),
                                              style: .done,
                                              target: self,
                                              action: selector)
        navigationItem.rightBarButtonItem = rightButtonItem
    }
    
    /// 設置左側帶標題導航選項
    /// - Parameters:
    ///   - title: 標題
    ///   - selector: 觸發函數
    func setNavigationLeftTitleItem(_ title: String, _ selector: Selector) {
        let rightButtonItem = UIBarButtonItem(title: title, style: .done, target: self, action: selector)
        navigationItem.leftBarButtonItem = rightButtonItem
    }
    
    /// 設置右側帶標題導航選項
    /// - Parameters:
    ///   - title: 標題
    ///   - selector: 觸發函數
    func setNavigationRightTitleItem(_ title: String, _ selector: Selector) {
        let rightButtonItem = UIBarButtonItem(title: title, style: .done, target: self, action: selector)
        navigationItem.rightBarButtonItem = rightButtonItem
    }
    
    private struct AssociatedKeys {
        static var titleTapActionKey = "titleTapActionKey"
    }
    
    typealias TitleTapAction = () -> Void
    
    private var titleTapAction: TitleTapAction? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.titleTapActionKey) as? TitleTapAction
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.titleTapActionKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func setNavigationBarSubtitle(title: String, subtitle: String?, onTap: TitleTapAction? = nil) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.3
        titleLabel.sizeToFit()
        
        let subtitleLabel = UILabel()
        if let subtitle = subtitle {
            subtitleLabel.text = subtitle
            subtitleLabel.font = UIFont.systemFont(ofSize: 14)
            subtitleLabel.textColor = UIColor.secondaryLabelColor
            subtitleLabel.textAlignment = .center
            subtitleLabel.sizeToFit()
        }
        let stackView = UIStackView(arrangedSubviews: subtitle != nil ? [titleLabel, subtitleLabel] : [titleLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalCentering
        stackView.isUserInteractionEnabled = true
        if let onTap = onTap {
            titleTapAction = onTap
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapTitleView))
            stackView.addGestureRecognizer(tapGesture)
        }
        navigationItem.titleView = stackView
    }
    
    @objc private func didTapTitleView() {
        titleTapAction?()
    }
}
