//
//  Storyboard+.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/6/10.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import Foundation
import UIKit

public extension UIStoryboard {
    enum viewControllers {
        static var myQRCodeViewController: MyQRCodeViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "MyQRCodeViewController") as? MyQRCodeViewController
        }
        
        static var sesame2RoomMainVC: Sesame2HistoryViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "Sesame2HistoryViewController") as? Sesame2HistoryViewController
        }
        
        static var bluetoothDevicesListViewController: BluetoothDevicesListViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "BluetoothDevicesListViewController") as? BluetoothDevicesListViewController
        }
        
        static var friendsViewController: FriendsViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "FriendsViewController") as? FriendsViewController
        }
        
        static var meViewController: MeViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "MeViewController") as? MeViewController
        }
        
        static var generalTabViewController: GeneralTabViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "GeneralTabViewController") as? GeneralTabViewController
        }
        
        static var sesame2SettingVC: Sesame2SettingViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "Sesame2SettingViewController") as? Sesame2SettingViewController
        }
        
        static var chTFDialogVC: CHTFDialogViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "CHTFDialogViewController") as? CHTFDialogViewController
        }
        
        static var chSesame2ChangeNameDialog: CHSesame2ChangeNameDialog? {
            Constant.storyboard.instantiateViewController(withIdentifier: "CHSesame2ChangeNameDialog") as? CHSesame2ChangeNameDialog
        }
        
        static var loginViewController: LogInViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LogInViewController
        }
        
        static var forgotPasswordViewController: ForgotPasswordViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "ForgotPasswordViewController") as? ForgotPasswordViewController
        }
        
        static var signUpViewController: SignUpViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "SignUpViewController") as? SignUpViewController
        }
        
        static var scanViewController: ScanViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "ScanViewController") as? ScanViewController
        }
        
        static var lockAngleSettingViewController: LockAngleSettingViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "LockAngleSettingViewController") as? LockAngleSettingViewController
        }
        
        static var registerDeviceListVC: RegisterDeviceListViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "RegisterDeviceListViewController") as? RegisterDeviceListViewController
        }

        static var bluetoothSesameControlViewController: BluetoothSesame2ControlViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "BluetoothSesame2ControlViewController") as? BluetoothSesame2ControlViewController
        }
        
        static var registerWifiModule2TableViewController: RegisterWifiModule2ViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "RegisterWifiModule2ViewController") as? RegisterWifiModule2ViewController
        }
        
        static var wifiModule2ListViewController: WifiModule2ListViewController? {
            Constant.wifiStoryboard.instantiateViewController(withIdentifier: "WifiModule2ListViewController") as? WifiModule2ListViewController
        }
        
        static var wifiSelectionTableViewController: WifiSelectionTableViewController? {
            Constant.wifiStoryboard.instantiateViewController(withIdentifier: "WifiSelectionTableViewController") as? WifiSelectionTableViewController
        }
    }
}
