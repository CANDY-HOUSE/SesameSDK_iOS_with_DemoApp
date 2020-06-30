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
            Constant.storyboard.instantiateViewController(withIdentifier: "MyQrVC") as? MyQRCodeViewController
        }
        
        static var ssm2RoomMainVC: SSM2RoomMainViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "SSM2RoomMainVC") as? SSM2RoomMainViewController
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
        
        static var ssm2SettingVC: SSM2SettingViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "SSM2SettingVC") as? SSM2SettingViewController
        }
        
        static var chTFDialogVC: CHTFDialogViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "alert") as? CHTFDialogViewController
        }
        
        static var chSSMChangeNameDialog: CHSSMChangeNameDialog? {
            Constant.storyboard.instantiateViewController(withIdentifier: "ssmalert") as? CHSSMChangeNameDialog
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
            Constant.storyboard.instantiateViewController(withIdentifier: "RegisterDeviceListVC") as? RegisterDeviceListViewController
        }
        
//        static var addFriendViewController: AddFriendViewController? {
//            Constant.storyboard.instantiateViewController(withIdentifier: "AddFriendViewController") as? AddFriendViewController
//        }
//        
//        static var deleteFriendVC: DeleteFriendViewController? {
//            Constant.storyboard.instantiateViewController(withIdentifier: "DeleteFriendVC") as? DeleteFriendViewController
//        }
        
        static var bluetoothSesameControlViewController: BluetoothSesameControlViewController? {
            Constant.storyboard.instantiateViewController(withIdentifier: "BluetoothSesameControlViewController") as? BluetoothSesameControlViewController
        }
    }
}
