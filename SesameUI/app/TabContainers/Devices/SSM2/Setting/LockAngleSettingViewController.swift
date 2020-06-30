//
//  setLockVC.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/10/11.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import UIKit
import SesameSDK
import CoreBluetooth

class LockAngleSettingViewController: CHBaseViewController  {
    var viewModel: LockAngleSettingViewModel!
    
    @IBOutlet weak var topHintLabel: UILabel!
    @IBOutlet weak var bottomHintLabel: UILabel!
    
    @IBOutlet weak var setLockImage: UIImageView!
    @IBOutlet weak var setUnlockImage: UIImageView!
    
    @IBOutlet weak var setLockButton: UIButton!
    @IBOutlet weak var setUnlockButton: UIButton!
    
    @IBOutlet weak var sesameView: SesameView!
    @IBAction func setLock(_ sender: UIButton) {
        viewModel.setLock()
    }


    @IBAction func setUnlock(_ sender: UIButton) {
        viewModel.setUnlock()
    }
    
    @IBAction func setSesame(_ sender: UIButton) {
        viewModel.sesameTapped()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(viewModel != nil, "LockAngleSettingViewModel should not be nil")
        viewModel.statusUpdated = { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            switch status {
            case .loading:
                break
            case .received:
                executeOnMainThread {
                    strongSelf.refreshUI()
                }
            case .finished(let result):
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    break
                }
                break
            }
        }
        sesameView.viewModel = viewModel.sesameViewModel()
        viewModel.viewDidLoad()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshUI()
        navigationItem.title = viewModel.title
    }
    
    public func refreshUI() {
        setLockImage.image = UIImage.SVGImage(named: viewModel.setLockImage)
        setUnlockImage.image = UIImage.SVGImage(named: viewModel.setUnlockImage)
        bottomHintLabel.text = viewModel.hintContent
        topHintLabel.text = viewModel.hintTitle
        setLockButton.setTitle(viewModel.setLockButtonTitle, for: .normal)
        setUnlockButton.setTitle(viewModel.setUnlockButtonTitle, for: .normal)
        sesameView?.refreshUI()
    }
    
    deinit {
        L.d("LockAngleSettingViewController")
    }
}

