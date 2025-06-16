//
//  QRScannerView.swift
//  QRCodeReader
//
//  Created by KM, Abhilash a on 08/03/19.
//  Copyright © 2019 KM, Abhilash. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import SesameSDK

/// Delegate callback for the QRScannerView.
protocol QRScannerViewDelegate: AnyObject {
    func qrScanningDidFail()
    func qrScanningSucceededWithCode(_ str: String?)
    func qrScanningDidStop()
}

class QRScannerView: UIView {

    weak var delegate: QRScannerViewDelegate?

    /// capture settion which allows us to start and stop scanning.
    var captureSession: AVCaptureSession?
    var detectPreference: [String]?

    // Init methods
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.connection?.videoOrientation = .landscapeLeft
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    // MARK: overriding the layerClass to return `AVCaptureVideoPreviewLayer`.
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    override var layer: AVCaptureVideoPreviewLayer {
        return super.layer as! AVCaptureVideoPreviewLayer
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        doInitialSetup()
    }
}

extension QRScannerView {

    var isRunning: Bool {
        return captureSession?.isRunning ?? false
    }

    func startScanning() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }
    }

    func stopScanning() {
        captureSession?.stopRunning()
        delegate?.qrScanningDidStop()
    }

    /// Does the initial setup for captureSession
    private func doInitialSetup() {
        clipsToBounds = true
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch let error {
            print(error)
            return
        }

        if (captureSession?.canAddInput(videoInput) ?? false) {
            captureSession?.addInput(videoInput)
        } else {
            scanningDidFail()
            return
        }
        self.layer.videoGravity = .resizeAspectFill
        self.layer.session = self.captureSession
        let metadataOutput = AVCaptureMetadataOutput()
        DispatchQueue.global(qos: .userInitiated).async {
            if (self.captureSession?.canAddOutput(metadataOutput) ?? false) {
                self.captureSession?.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr, .ean8, .ean13, .pdf417]
                self.captureSession?.startRunning()
            } else {
                self.scanningDidFail()
                return
            }
        }
    }
    
    func scanningDidFail() {
        delegate?.qrScanningDidFail()
        captureSession = nil
    }

    func found(code: String) {
        delegate?.qrScanningSucceededWithCode(code)
    }

}

extension QRScannerView: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            if let getPreference = detectPreference, (getPreference.first(where: { stringValue.hasPrefix($0) }) == nil) {
                L.d("Not a sesame product")
                return
            }
            stopScanning()
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
    }
}
