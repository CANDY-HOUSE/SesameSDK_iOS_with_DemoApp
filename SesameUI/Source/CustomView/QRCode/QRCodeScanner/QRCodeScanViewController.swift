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

class QRCodeScanViewController: CHBaseViewController {

    let qrScannerView = QRScannerView(frame: .zero)
    let scanAnimationView = ScanAnimationView(frame: .zero)
    var dismissHandler: ((Bool)->Void)?
    private var isReceivedKey = false
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dismissButton = UIButton(type: .custom)
        dismissButton.setTitle("", for: .normal)
        dismissButton.setImage(UIImage.SVGImage(named: "icons_filled_close_b"), for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        
        let displayLabel = UILabel(frame: .zero)
        displayLabel.translatesAutoresizingMaskIntoConstraints = false
        displayLabel.text = "co.candyhouse.sesame-sdk-test-app.ScanTheQRCode".localized
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
        
        scanAnimationView.scanAnimationImage = UIImage.CHUIImage(named: "ScanLine")!
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(rotatedCamera),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        rotatedCamera()
        
        qrScannerView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBarTintColor(.darkText)
        tabBarController?.tabBar.backgroundColor = .darkText
        
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
    
    // MARK: - Method
    
    
    
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
            let cancelAction = UIAlertAction(title: "co.candyhouse.sesame-sdk-test-app.Cancel".localized,
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
        if let supportedOrientations = Bundle.resourceBundle.object(forInfoDictionaryKey: "UISupportedInterfaceOrientations") as? [String] {
            
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
        dismissHandler?(self.isReceivedKey)
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
        guard let url = Bundle.resourceBundle.url(forResource: "bee", withExtension: "mp3") else { return }
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
            let sesame2Key = scanSchema.sesame2Key() else {
                return
        }
        
        let encodedHistoryTag = "のび太".data(using: .utf8)!
        
        let tokenFetchLock = DispatchGroup()
        
        CHDeviceManager.shared.receiveSesame2Keys(sesame2Keys: [sesame2Key]) { result in
            switch result {
            case .success(let sesame2):

                for sesame2 in sesame2.data {
                    tokenFetchLock.enter()
                    Sesame2Store.shared.deletePropertyAndHisotryForDevice(sesame2)
                    sesame2.setHistoryTag(encodedHistoryTag) {_ in
                        tokenFetchLock.leave()
                    }
                }

                tokenFetchLock.wait()
                self.isReceivedKey = true
                self.dismissSelf()
                
            case .failure(_):
                break
            }
        }
    }
}

// MARK: - Designated Initializer
extension QRCodeScanViewController {
    static func instance(dismissHandler: ((Bool)->Void)? = nil) -> QRCodeScanViewController {
        let qrCodeScanViewController = QRCodeScanViewController(nibName: nil, bundle: nil)
        qrCodeScanViewController.dismissHandler = dismissHandler
        return qrCodeScanViewController
    }
}
