//
//  SessionMoreMenuView.swift
//
//  Created by xu.shuifeng on 2019/7/4.
//  Copyright © 2019 alexiscn. All rights reserved.
//

import UIKit

public struct PopUpMenuItem {
    
    var type: MoreItemType
    
    var title: String
    
    var icon: String
    
    enum MoreItemType {
        case addSesame2
        case receiveKey
    }
}

protocol PopUpMenuDelegate {
    func popUpMenu(_ menu: PopUpMenu, didTap item: PopUpMenuItem)
}

class TriangleView : UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {

        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.beginPath()
        context.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        context.addLine(to: CGPoint(x: (rect.maxX / 2.0), y: rect.minY))
        context.closePath()

        context.setFillColor(UIColor.darkGray.cgColor)
        context.fillPath()
    }
}

class PopUpMenu: UIView {
    
    var delegate: PopUpMenuDelegate?
    
    private let backgroundView: UIImageView
    
    private let containerView: UIView
    
    private let menus: [PopUpMenuItem]
    
    init(itemHeight: CGFloat, itemWidth: CGFloat, menus: [PopUpMenuItem]) {
        
        self.menus = menus
        
        backgroundView = UIImageView()
        
        containerView = UIView()
        
        var buttons: [UIButton] = []
        for (index, menu) in menus.enumerated() {
            let menuIcon = UIImage.SVGImage(named: menu.icon, fillColor: .white)
            let button = UIButton(type: .custom)
            button.contentHorizontalAlignment = .left
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: -20)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: -30)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            button.frame = CGRect(x: 0, y: itemHeight * CGFloat(index), width: itemWidth, height: itemHeight)
            button.tintColor = .white
            button.setImage(menuIcon, for: .normal)
            button.setImage(menuIcon, for: .highlighted)
            button.layer.cornerRadius = 4
            button.layer.masksToBounds = true
            button.setBackgroundImage(UIImage(color: .sesame2Green), for: .highlighted)
            button.setTitle(menu.title, for: .normal)
            button.setTitleColor(UIColor.white, for: .normal)
            button.tag = index
            containerView.addSubview(button)
            
            if index != menus.count - 1 {
                let line = UIImageView()
                line.image = UIImage.CHUIImage(named: "MoreFunctionFrameLine_120x0_")
                let lineHeight = 1/UIScreen.main.scale
                line.frame = CGRect(x: 50, y: itemHeight - lineHeight, width: itemWidth - 50, height: lineHeight)
                button.addSubview(line)
            }
            buttons.append(button)
        }
        containerView.frame = CGRect(x: 0, y: 10, width: itemWidth, height: itemHeight * CGFloat(menus.count))
        
        let frame = CGRect(x: 0, y: 0, width: itemWidth, height: containerView.frame.maxY)
        
        super.init(frame: frame)
        
        backgroundView.frame = bounds
        
        let gray = UIImageView(frame: CGRect(x: 0, y: 10, width: backgroundView.frame.size.width, height: backgroundView.frame.size.height-10))
        gray.image = UIImage(color: .darkGray, size: CGSize(width: backgroundView.frame.size.width, height: backgroundView.frame.size.height-10))
        gray.layer.cornerRadius = 5.0
        gray.layer.masksToBounds = true
        backgroundView.addSubview(gray)
        
        let triangle = TriangleView(frame: CGRect(x: backgroundView.frame.size.width-30, y: 0, width: 20, height: 10))
        backgroundView.addSubview(triangle)
        
        addSubview(backgroundView)
        addSubview(containerView)
        
        buttons.forEach { $0.addTarget(self, action: #selector(handleTapMenuButton(_:)), for: .touchUpInside) }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handleTapMenuButton(_ sender: UIButton) {
        let item = menus[sender.tag]
        delegate?.popUpMenu(self, didTap: item)
    }
    
}
