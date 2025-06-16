//
//  QRCodeScanViewController.swift
//  SesameUI
//
//  Created by YuHan Hsiao on 2020/9/12.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import SesameSDK
import AVFoundation
import AWSMobileClientXCF

class QRCodeScanViewController: CHBaseViewController {

    let qrScannerView = QRScannerView(frame: .zero)
    let scanAnimationView = ScanAnimationView(frame: .zero)
    var dismissHandler: ((QRcodeType?)->Void)?
    private var qrCodeType: QRcodeType?
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBarBackgroundColor = .black
        
        let dismissButton = UIButton(type: .custom)
        dismissButton.setTitle("", for: .normal)
        dismissButton.setImage(UIImage.SVGImage(named: "icons_filled_close_b"), for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        
        let displayLabel = UILabel(frame: .zero)
        displayLabel.translatesAutoresizingMaskIntoConstraints = false
        displayLabel.text = "co.candyhouse.sesame2.ScanTheQRCode".localized
        displayLabel.textAlignment = .center
        displayLabel.textColor = .white

        let albumImage = UIImage.SVGImage(named: "icons_filled_album",
                                     fillColor: .white)
        let width = 50
        let albumImageView = UIImageView(frame: .init(x: 0, y: 0, width: width, height: width))
        albumImageView.image = albumImage
        albumImageView.contentMode = .center
        albumImageView.backgroundColor = UIColor.darkGray
        albumImageView.layer.cornerRadius = CGFloat(width/2)
        albumImageView.layer.masksToBounds = true
        let renderer = UIGraphicsImageRenderer(bounds: albumImageView.bounds)
        let circleImage = renderer.image { rendererContext in
            albumImageView.layer.render(in: rendererContext.cgContext)
        }
        let albumButton = UIButton(type: .custom)
        albumButton.setImage(circleImage, for: .normal)
        albumButton.setTitle(nil, for: .normal)
        albumButton.addTarget(self, action: #selector(openAlbum), for: .touchUpInside)
        
        qrScannerView.backgroundColor = .clear
        scanAnimationView.backgroundColor = .clear
        
        view.addSubview(qrScannerView)
        view.addSubview(scanAnimationView)
        view.addSubview(dismissButton)
        view.addSubview(displayLabel)
        view.addSubview(albumButton)
        
        qrScannerView.autoPinEdgesToSuperview(safeArea: false)
        scanAnimationView.autoPinEdgesToSuperview(safeArea: false)
        displayLabel.autoPinCenterX()
        displayLabel.autoPinCenterY(constant: scanAnimationView.contentView.frame.height / 3 + 70)
        displayLabel.autoPinLeading()
        displayLabel.autoPinTrailing()
        
        albumButton.autoPinCenterX()
        albumButton.autoPinTopToBottomOfView(displayLabel, constant: 20)
        albumButton.autoPinLeading()
        albumButton.autoPinTrailing()
        
        dismissButton.autoPinTop(constant: 20)
        dismissButton.autoPinTrailing(constant: -20)
        dismissButton.autoLayoutWidth(40)
        dismissButton.autoLayoutHeight(40)
        
        scanAnimationView.scanAnimationImage = UIImage(named: "ScanLine")!
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(rotatedCamera),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        rotatedCamera()
        
        qrScannerView.detectPreference = [URL.sesameURLSchemePrefix]
        qrScannerView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !qrScannerView.isRunning {
            qrScannerView.startScanning()
        }
        
        cameraEnable()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !qrScannerView.isRunning {
            qrScannerView.stopScanning()
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scanAnimationView.startAnimation()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scanAnimationView.stopAnimation()
    }
    
    // MARK: cameraEnable
    func cameraEnable() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if (authStatus == .authorized) {
            
        }
        else if (authStatus == .denied) {
            let okAction = UIAlertAction(title:"setting", style: UIAlertAction.Style.default) {
                UIAlertAction in
                let url = URL(string: UIApplication.openSettingsURLString)
                if let url = url, UIApplication.shared.canOpenURL(url) {
                    if #available(iOS 10, *) {
                        UIApplication.shared.open(url, options: [:],
                                                  completionHandler: {
                                                    (success) in
                        })
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }
                DispatchQueue.main.async {
                    self.dismissSelf()
                }
            }
            let cancelAction = UIAlertAction(title: "co.candyhouse.sesame2.Cancel".localized,
                                             style: UIAlertAction.Style.cancel) {
                UIAlertAction in
                DispatchQueue.main.async {
                    self.dismissSelf()
                }
            }
            let alert = UIAlertController(title: title, message: "camara privacy", preferredStyle: .alert)
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            alert.popoverPresentationController?.sourceView = view
            alert.popoverPresentationController?.sourceRect = .init(x: view.center.x,
                                                                    y: view.center.y,
                                                                    width: 0,
                                                                    height: 0)
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        } else if (authStatus == .restricted) {
            
        } else if (authStatus == .notDetermined) {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (statusFirst) in
                
            })
        }
    }
    
    // MARK: rotatedCamera
    @objc private func rotatedCamera() {
        if let supportedOrientations = Bundle.main.object(forInfoDictionaryKey: "UISupportedInterfaceOrientations") as? [String] {
            
            switch UIDevice.current.orientation {
            case .portrait:
                qrScannerView.layer.connection?.videoOrientation = supportedOrientations.contains("UIInterfaceOrientationPortrait") ? .portrait : .portrait
            case .portraitUpsideDown:
                qrScannerView.layer.connection?.videoOrientation = supportedOrientations.contains("UIInterfaceOrientationPortraitUpsideDown") ? .portraitUpsideDown : .portrait
            case .landscapeLeft:
                qrScannerView.layer.connection?.videoOrientation = supportedOrientations.contains("UIInterfaceOrientationLandscapeLeft") ? .landscapeRight : .portrait
            case .landscapeRight:
                qrScannerView.layer.connection?.videoOrientation = supportedOrientations.contains("UIInterfaceOrientationLandscapeRight") ? .landscapeLeft : .portrait
            case .faceUp:
                qrScannerView.layer.connection?.videoOrientation = supportedOrientations.contains("UIInterfaceOrientationPortrait") ? .portrait : .portrait
            case .faceDown:
                qrScannerView.layer.connection?.videoOrientation = supportedOrientations.contains("UIInterfaceOrientationPortrait") ? .portrait : .portrait
            case .unknown:
                qrScannerView.layer.connection?.videoOrientation = supportedOrientations.contains("UIInterfaceOrientationPortrait") ? .portrait : .portrait
            @unknown default:
                break
            }
        }
    }
    
    // MARK: openAlbum
    @objc func openAlbum() {
        QRCodeExtractor.shared.presentImagePicker(self) { result in
            switch result {
            case .success(let qrCode):
                self.receivedQRCode(qrCode)
            case .failure(let error):
                self.view.makeToast(error.errorDescription())
            }
        }
    }
    
    // MARK: dismissSelf
    @objc func dismissSelf() {
        dismiss(animated: true, completion: nil)
        dismissHandler?(self.qrCodeType)
    }
}

// MARK: - QRScannerViewDelegate
extension QRCodeScanViewController: QRScannerViewDelegate {
    func qrScanningDidFail() {
        
    }
    
    func qrScanningDidStop() {
        
    }
    
    func qrScanningSucceededWithCode(_ qrCode: String?) {
        playSound()
        receivedQRCode(qrCode)
    }
    
    // MARK: playSound
    func playSound() {
        guard let url = Bundle.main.url(forResource: "bee", withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            soundPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            guard let player = soundPlayer else { return }
            player.play()
        } catch let error {
            L.d(error.localizedDescription)
        }
    }
    
    // MARK: receivedQRCode
    func receivedQRCode(_ qrCodeURL: String?) {
        guard let urlString = qrCodeURL,
              let scanSchema = URL(string: urlString),
              let scheme = scanSchema.scheme,
              let host = scanSchema.host,
              scheme + "://" + host == URL.sesameURLSchemePrefix
        else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let _ = scanSchema.schemaShareKeyValue() {
                ViewHelper.showLoadingInView(view: self.view)
                let keyLevelValue = Int(scanSchema.getQuery(name: "l")) ?? 1
                //            let keyLevel = KeyLevel(rawValue: keyLevelValue)
                let deviceName = scanSchema.getQuery(name: "n")
                self.saveKeysAndUpload(scanSchema, keyLevel: keyLevelValue, deviceName: deviceName)
            } else if let friend = scanSchema.schemaFriendValue() {
                CHUserAPIManager.shared.postFriend(friend) { result in
                    executeOnMainThread {
                        self.qrCodeType = .friend
                        self.dismissSelf()
                    }
                }
            }
        }
    }
    
    private func saveKeysAndUpload(_ qrCodeURL: URL, keyLevel: Int, deviceName: String? = nil) {
        guard let deviceKey = qrCodeURL.deviceKeyFromQRCodeURL() else {
            return
        }
        CHDeviceManager.shared.receiveCHDeviceKeys([deviceKey]) { result in
            switch result {
            case .success(let devices):

                guard let device = devices.data.first else {
                    return
                }
                // Set KeyLevel
                Sesame2Store.shared.deletePropertyFor(device)
                device.setKeyLevel(keyLevel)
                // Set Device Name
                if let deviceName = deviceName {
                    device.setDeviceName(deviceName)
                }
                // Set History Tag
                CHDeviceManager.shared.setHistoryTag()
                if AWSMobileClient.default().currentUserState == .signedIn {
                    var userKey = CHUserKey.userKeyFromCHDevice(device, keyLevel: keyLevel)
                    // Upload Key
                    CHUserAPIManager.shared.getSubId { subId in
                        guard let subId = subId else {
                            executeOnMainThread {
                                ViewHelper.hideLoadingView(view: self.view)
                                self.view.makeToast(NSError.noSubId.errorDescription())
                            }
                            return
                        }
                        userKey.subUUID = subId
                        CHUserAPIManager.shared.putCHUserKey(userKey) { _ in
                            executeOnMainThread {
                                ViewHelper.hideLoadingView(view: self.view)
                                self.qrCodeType = .sesameKey
                                self.dismissSelf()
                            }
                        }
                    }
                } else {
                    executeOnMainThread {
                        ViewHelper.hideLoadingView(view: self.view)
                        self.qrCodeType = .sesameKey
                        self.dismissSelf()
                    }
                }
            case .failure(_):
                executeOnMainThread {
                    ViewHelper.hideLoadingView(view: self.view)
                    self.view.makeToast("Scan QR code failed")
                }
            }
        }
    }
}

extension QRCodeScanViewController {
    static func parseSesameQRCode(_ qrCodeURL: String, handler: @escaping ((Result<QRcodeType, Error>)->Void)) {
        guard let scanSchema = URL(string: qrCodeURL) else {
                return
        }
        if let _ = scanSchema.schemaShareKeyValue() {
            let keyLevelValue = Int(scanSchema.getQuery(name: "l")) ?? 1
            let keyLevel = KeyLevel(rawValue: keyLevelValue) ?? .guest
            let deviceName = scanSchema.getQuery(name: "n")
            guard let deviceKey = scanSchema.deviceKeyFromQRCodeURL() else {
                return
            }

            CHDeviceManager.shared.receiveCHDeviceKeys([deviceKey]) { result in
                switch result {
                case .success(let devices):

                    guard let device = devices.data.first else {
                        return
                    }
                    // Set KeyLevel
                    Sesame2Store.shared.deletePropertyFor(device)
                    device.setKeyLevel(keyLevel.rawValue)
                    // Set Device Name
                    device.setDeviceName(deviceName)
                    // Set History Tag
                    CHDeviceManager.shared.setHistoryTag()

                    if AWSMobileClient.default().currentUserState == .signedIn {
                        var userKey = CHUserKey.userKeyFromCHDevice(device, keyLevel: keyLevel.rawValue)
                        // Upload Key
                        CHUserAPIManager.shared.getSubId { subId in
                            guard let subId = subId else {
                                handler(.failure(NSError.noSubId))
                                return
                            }
                            userKey.subUUID = subId
                            CHUserAPIManager.shared.putCHUserKey(userKey) { _ in
                                handler(.success(.sesameKey))
                            }
                        }
                    } else {
                        handler(.success(.sesameKey))
                    }
                case .failure(_):
                    handler(.failure(NSError.invalidQRCode))
                }
            }
        } else if let friend = scanSchema.schemaFriendValue() {
            CHUserAPIManager.shared.postFriend(friend) { postResult in
                switch postResult {
                case .success(_):
                    handler(.success(.friend))
                case .failure(let error):
                    handler(.failure(error))
                }
            }
        }
    }
}

// MARK: - Designated Initializer
extension QRCodeScanViewController {
    static func instance(dismissHandler: ((QRcodeType?)->Void)? = nil) -> QRCodeScanViewController {
        let qrCodeScanViewController = QRCodeScanViewController(nibName: nil, bundle: nil)
        qrCodeScanViewController.dismissHandler = dismissHandler
        return qrCodeScanViewController
    }
}
