//
//  MeViewController.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/10/9.
//  Copyright © 2019 CandyHouse. All rights reserved.
//

import UIKit

public protocol MeDelegate: class {
    func setLoginName()
}

class MeViewController: CHBaseViewController {
    
    var viewModel: MeViewModel!
    
    @IBOutlet weak var changeAccountName: UILabel!
    @IBOutlet weak var familyName: UILabel!
    @IBOutlet weak var givenName: UILabel!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var avatarImg: UIImageView!
    @IBOutlet weak var qrImg: UIImageView!
    @IBOutlet weak var logoutBtn: UIButton!
    
    @IBOutlet weak var nonLoggedInHeaderView: UIView!
    @IBOutlet weak var loggedInHeaderView: UIView!
    
    @IBOutlet var nonLoggedInComponents: [UIView]!
    @IBOutlet var loggedInComponents: [UIView]!
    
    private var menuFloatView: PopUpMenuControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(viewModel != nil, "MeViewModel should not be nil")
        
        viewModel.statusUpdated = { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            switch status {
            case .loading:
                break
            case .update:
                executeOnMainThread {
                    strongSelf.setContentWithIsLoggedIn(strongSelf.viewModel.isSignedIn)
                }
            case .finished(let result):
                switch result {
                case .success(_):
                    executeOnMainThread {
                        strongSelf.setLoginName()
                    }
                case .failure(_):
                    break
                }
            }
        }
        
        if #available(iOS 13.0, *) {
            let previouseColor = navigationController?.navigationBar.standardAppearance.backgroundColor ?? .white
            navigationBarTintColor = .init(current: UIColor.white, previous: previouseColor)
        } else {
            let previouseColor = navigationController?.navigationBar.tintColor ?? .white
            navigationBarTintColor = .init(current: UIColor.white, previous: previouseColor)
        }
        
        if #available(iOS 13.0, *) {
            self.navigationController?.navigationBar.standardAppearance.shadowColor = .clear
        } else {
            // Fallback on earlier versions
        }
        
        setContentWithIsLoggedIn(viewModel.isSignedIn)
       
        logoutBtn.setTitle(viewModel.logoutButtonTitle, for: .normal)
        changeAccountName.text = viewModel.changeAccountNameText

        email.adjustsFontSizeToFitWidth = true

        let rightButtonItem = UIBarButtonItem(image: UIImage.SVGImage(named: viewModel.rightButtonImage),
                                              style: .done,
                                              target: self,
                                              action: #selector(handleRightBarButtonTapped(_:)))
        navigationItem.rightBarButtonItem = rightButtonItem
        qrImg.image = UIImage.SVGImage(named: viewModel.qrCodeIcon)
        
        let versionLabel = VersionLabel()
        view.addSubview(versionLabel)

        let constraints = [
            versionLabel.centerXAnchor.constraint(equalTo: logoutBtn.centerXAnchor),
            versionLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                                                 constant: -90),
            versionLabel.widthAnchor.constraint(equalTo: view.widthAnchor),
            versionLabel.heightAnchor.constraint(equalToConstant: 40)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear()
    }
    
    func setContentWithIsLoggedIn(_ isLoggedIn: Bool) {
        for nonLoggedIncomponent in nonLoggedInComponents {
            nonLoggedIncomponent.isHidden = isLoggedIn
        }
        for loggedInComponent in loggedInComponents {
            loggedInComponent.isHidden = !isLoggedIn
        }
    }
    
    @IBAction func logOut(_ sender: UIButton) {
        let check = UIAlertAction.addAction(title: viewModel.logOutButtonTitle,
                                            style: .destructive) { (action) in
            self.viewModel.logOutTapped()
        }
        UIAlertController.showAlertController(sender,
                                              style: .actionSheet,
                                              actions: [check])
    }
    
    @IBAction func changeAccount(_ sender: Any) {

        CHTFDialogViewController.show() { lastName, firstName in
            self.viewModel.modifyAccountNameTapped(lastName: lastName,
                                                   firstName: firstName)
        }
    }
    
    @IBAction func loginRegister(_ sender: Any) {
        viewModel.loginRegisterTapped()
    }
    
    @IBAction func showQRCodeTapped(_ sender: Any) {
        viewModel.showQRCodeTapped()
    }
    
    
}

extension MeViewController: MeDelegate {
    func setLoginName() {
        self.givenName.text = viewModel.givenName
        self.familyName.text = viewModel.familyName
        self.avatarImg.image = UIImage.makeLetterAvatar(withUsername: viewModel.avatarImage)
        self.email.text = viewModel.email
    }
}

extension MeViewController: PopUpMenuDelegate {
    private func showMoreMenu() {
        if menuFloatView == nil {
            let y = Constant.statusBarHeight + 44
            let frame = CGRect(x: 0, y: y, width: view.bounds.width, height: view.bounds.height - y)
            menuFloatView = PopUpMenuControl(frame: frame)
            menuFloatView?.delegate = self
        }
        menuFloatView?.show(in: self.view)
    }
    
    private func hideMoreMenu(animated: Bool = true) {
        menuFloatView?.hide(animated: animated)
    }
    @objc private func handleRightBarButtonTapped(_ sender: Any) {
        if self.menuFloatView?.superview != nil {
            hideMoreMenu()
        } else {
            showMoreMenu()
        }
    }
    
    func popUpMenu(_ menu: PopUpMenu, didTap item: PopUpMenuItem) {
        viewModel.popUpMenuTappedOnItem(item)
        hideMoreMenu(animated: false)
    }
}
