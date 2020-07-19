//
//  ScanViewController.swift
//  sesame-sdk-test-app
//
//  Created by tse on 2019/9/27.
//  Copyright © 2019 Cerberus. All rights reserved.
//

import UIKit
import SesameSDK
import AVFoundation

class ScanViewController: CHBaseViewController {
    
    
    @IBOutlet weak var hintLb: UILabel!

    @IBOutlet weak var scannerView: QRScannerView! {
        didSet {
            scannerView.delegate = self
        }
    }
    @IBOutlet weak var scanViewSp: ScanView!

    @IBOutlet weak var back: UIButton!
    
    var viewModel: ScanViewModel!

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !scannerView.isRunning {
            scannerView.stopScanning()
        }
    }

    @IBAction func backClick(_ sender: Any) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion:nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {        
        super.viewWillAppear(animated)
        if !scannerView.isRunning {
            scannerView.startScanning()
        }
        cameraEnable()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(viewModel != nil, "ScanViewModel should not be nil")
        
        viewModel.statusUpdated = { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            executeOnMainThread {
                switch status {
                case .loading:
                    break
                case .received:
                    break
                case .finished(let result):
                    switch result {
                    case .success(_):
                        break
                    case .failure(let error):
                        strongSelf.view.makeToast(error.errorDescription())
                    }
                }
            }
        }
        
        scanViewSp.scanAnimationImage = UIImage.CHUIImage(named: "ScanLine")!
        hintLb.text = "Scan the QR code".localStr
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(rotatedCamera),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        rotatedCamera()
        back.setImage( UIImage.SVGImage(named: "icons_filled_close_b"), for: .normal)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scanViewSp.startAnimation()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scanViewSp.stopAnimation()
    }
    
    func cameraEnable() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        if (authStatus == .authorized) {
            //                L.d("掃描已經授權")
        }
        else if (authStatus == .denied) {
            L.d("掃描denied")
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
                    self.dismiss(animated: true, completion:nil)
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
                UIAlertAction in
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion:nil)
                }
            }
            let alert = UIAlertController(title: title, message: "camara privacy", preferredStyle: .alert)
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
            
        else if (authStatus == .restricted) {
            L.d("掃描restricted")
        }
        else if (authStatus == .notDetermined) {
            L.d("掃描未決定授權")
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (statusFirst) in
                
            })
        }
    }
    
    @objc
    private func rotatedCamera() {
        if let supportedOrientations = Constant.resourceBundle.object(forInfoDictionaryKey: "UISupportedInterfaceOrientations") as? [String] {
            
            switch UIDevice.current.orientation {
            case .portrait:
                scannerView.layer.connection?.videoOrientation = supportedOrientations.contains("UIInterfaceOrientationPortrait") ? .portrait : .portrait
            case .portraitUpsideDown:
                scannerView.layer.connection?.videoOrientation = supportedOrientations.contains("UIInterfaceOrientationPortraitUpsideDown") ? .portraitUpsideDown : .portrait
            case .landscapeLeft:
                scannerView.layer.connection?.videoOrientation = supportedOrientations.contains("UIInterfaceOrientationLandscapeLeft") ? .landscapeRight : .portrait
            case .landscapeRight:
                scannerView.layer.connection?.videoOrientation = supportedOrientations.contains("UIInterfaceOrientationLandscapeRight") ? .landscapeLeft : .portrait
            case .faceUp:
                break
            case .faceDown:
                break
            case .unknown:
                break
            @unknown default:
                break
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

extension ScanViewController: QRScannerViewDelegate {
    func qrScanningDidStop() {
    }

    func qrScanningDidFail() {
        L.d("qrScanningDidFail")
    }

    func qrScanningSucceededWithCode(_ qrCode: String?) {
        playSound()
        viewModel.receivedQRCode(qrCode)
//        guard let urlString = qrCode,
//            let scanSchema = URL(string: urlString),
//            let sesame2Key = scanSchema.sesame2Key() else {
//                let error = NSError(domain: "", code: 0, userInfo: ["error message": "Parse qr code url failed"])
//                L.d(error.errorDescription())
//                DispatchQueue.main.async {
//                    self.view.makeToast(error.errorDescription())
//                }
//                return
//        }
//
//        CHBleManager.shared.receiveKey(sesame2Keys: [sesame2Key]) { result in
//            switch result {
//            case .success(_):
//                self.dismiss(animated: true, completion: nil)
//            case .failure(let error):
//                DispatchQueue.main.async {
//                    self.view.makeToast(error.errorDescription())
//                }
//            }
//        }
    }
    
    func playSound() {
        guard let url = Constant.resourceBundle.url(forResource: "bee", withExtension: "mp3") else { return }
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
    
    func receivedFriendInvitation(invitation: String) {
        
    }
    
    func receivedShareKey(key: String) {
        
    }
}


