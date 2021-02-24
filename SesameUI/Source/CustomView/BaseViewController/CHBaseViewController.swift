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
    
    struct NavigationBarTintColor {
        let previous: UIColor
        let current: UIColor
        
        init (current: UIColor = .sesame2Gray, previous: UIColor) {
            self.current = current
            self.previous = previous
        }
    }
    
    // MARK: - Properties
    private var previouseNavigationTitle = ""
    
    public override var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    var soundPlayer: AVAudioPlayer?
    var navigationBarTintColor: NavigationBarTintColor?
    
    // MARK: - UI Components
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: .zero)
        view.addSubview(titleLabel)
        titleLabel.autoPinLeading()
        titleLabel.autoPinTrailing()
        titleLabel.autoPinCenterY()
        titleLabel.autoLayoutHeight(40)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.minimumScaleFactor = 0.01
        return titleLabel
    }()

    // MARK: - Life cycle
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
        
        if #available(iOS 12.0, *) {
            navigationItem.titleView = titleLabel
        } else {
            titleLabel.removeFromSuperview()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationBarTintColor = navigationBarTintColor {
            setupNavigationBarTintColor(navigationBarTintColor.current)
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let navigationBarTintColor = navigationBarTintColor {
            setupNavigationBarTintColor(navigationBarTintColor.previous)
        }
        previouseNavigationTitle = titleLabel.text ?? ""
        navigationItem.title = ""
    }
    
    func setupNavigationBarTintColor(_ color: UIColor) {
        if #available(iOS 13.0, *) {
            navigationController?.navigationBar.standardAppearance.backgroundColor = color
        } else {
            navigationController?.navigationBar.barTintColor = color
        }
    }
    
    public func didBecomeActive() {
        
    }
    
    public func didEnterBackground() {
        
    }
}
