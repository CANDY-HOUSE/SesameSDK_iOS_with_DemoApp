//
//  CHBaseVC.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2020/3/28.
//  Copyright © 2020 CandyHouse. All rights reserved.
//
import UIKit
import AVFoundation
import SesameSDK
import CoreBluetooth
import Foundation

public class CHBaseViewController: UIViewController {
    private var previouseNavigationTitle = ""
    lazy var titleLabel: UILabel = {
        
        let titleLabel = UILabel(frame: CGRect(x: 0,
                                               y: 0,
                                               width: 200,
                                               height: 40))
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.minimumScaleFactor = 0.01
        return titleLabel
    }()
    
    struct NavigationBarTintColor {
        let previous: UIColor
        let current: UIColor
        
        init (current: UIColor = .sesame2Gray, previous: UIColor) {
            self.current = current
            self.previous = previous
        }
    }
    
    var soundPlayer: AVAudioPlayer?
    var navigationBarTintColor: NavigationBarTintColor!

    public override func viewDidLoad() {
        super.viewDidLoad()

        let navigationBar = navigationController?.navigationBar
        navigationBar?.shadowImage = UIImage()
        
        if #available(iOS 13.0, *) {
            let previouseColor = navigationController?.navigationBar.standardAppearance.backgroundColor ?? .white
            navigationBarTintColor = .init(previous: previouseColor)
        } else {
            let previouseColor = navigationController?.navigationBar.tintColor ?? .white
            navigationBarTintColor = .init(previous: previouseColor)
        }
        navigationItem.titleView = titleLabel
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarTintColor(navigationBarTintColor.current)
        titleLabel.text = previouseNavigationTitle
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setupNavigationBarTintColor(navigationBarTintColor.previous)
        previouseNavigationTitle = titleLabel.text ?? ""
        titleLabel.text = ""
    }
}

extension CHBaseViewController {
    func setupNavigationBarTintColor(_ color: UIColor) {
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance.backgroundColor = color
        } else {
            navigationController?.navigationBar.barTintColor = color
        }
    }
}

