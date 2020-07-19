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
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarTintColor(navigationBarTintColor.current)
        navigationItem.title = previouseNavigationTitle
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setupNavigationBarTintColor(navigationBarTintColor.previous)
        previouseNavigationTitle = navigationItem.title ?? ""
        navigationItem.title = "co.candyhouse.sesame2app.back".localStr
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

