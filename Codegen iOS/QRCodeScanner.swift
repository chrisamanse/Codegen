//
//  QRCodeScanner.swift
//  Codegen
//
//  Created by Chris Amanse on 12/12/16.
//
//

import Foundation
import AVFoundation

public protocol QRCodeScannerDelegate: class {
    func qrCodeScanner(scanner: QRCodeScanner, didScan value: String)
}

public final class QRCodeScanner: NSObject {
    public let cameraController: CameraController
    public let metadataObjectTypes: [Any]
    public let previewLayer: CALayer
    
    public var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    public var overlayColor: CGColor {
        didSet {
            overlayLayer.borderColor = overlayColor
        }
    }
    public lazy var overlayLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        
        layer.strokeColor = self.overlayColor
        layer.lineWidth = 2
        layer.fillColor = nil
        
        return layer
    }()
    
    public weak var delegate: QRCodeScannerDelegate?
    
    fileprivate var qrCodeDetectedDate: Date?
    fileprivate var detectedTargetTimeInterval: TimeInterval = 0.8
    
    public init(previewLayer: CALayer, overlayColor: CGColor) {
        cameraController = CameraController()
        metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        self.previewLayer = previewLayer
        self.overlayColor = overlayColor
    }
    
    deinit {
        stopScanning()
    }
    
    public func startScanning() throws {
        let session = try cameraController.startSession(metadataObjectTypes: metadataObjectTypes, delegate: self)
        
        addPreviewLayer(from: session)
    }
    
    public func stopScanning() {
        cameraController.stopSession()
        
        removePreviewLayer()
    }
    
    public func setPreviewLayerNeedsUpdate() {
        captureVideoPreviewLayer?.frame = previewLayer.bounds
    }
    
    private func addPreviewLayer(from session: AVCaptureSession) {
        removePreviewLayer()
        
        guard let captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session) else {
            return
        }
        
        captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        captureVideoPreviewLayer.frame = previewLayer.bounds
        
        previewLayer.addSublayer(captureVideoPreviewLayer)
        previewLayer.addSublayer(overlayLayer)
        
        self.captureVideoPreviewLayer = captureVideoPreviewLayer
    }
    
    private func removePreviewLayer() {
        overlayLayer.removeFromSuperlayer()
        captureVideoPreviewLayer?.removeFromSuperlayer()
        captureVideoPreviewLayer = nil
    }
    
    fileprivate func createOverlayPath(from object: AVMetadataMachineReadableCodeObject) -> CGPath {
        let code = captureVideoPreviewLayer!.transformedMetadataObject(for: object) as! AVMetadataMachineReadableCodeObject
        let cornersDictionaries = code.corners as! [[String: CGFloat]]
        let corners = cornersDictionaries.lazy.map {
            self.captureVideoPreviewLayer!.convert(CGPoint(x: $0["X"]!, y: $0["Y"]!), to: self.overlayLayer)
        }
        
        let path = CGMutablePath()
        
        path.move(to: corners.first!)
        
        for i in 1 ..< corners.count {
            path.addLine(to: corners[i])
        }
        
        path.addLine(to: corners.first!)
        
        return path
    }
}

extension QRCodeScanner: AVCaptureMetadataOutputObjectsDelegate {
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        guard let objects = metadataObjects else { return }
        guard let qrCodes = objects as? [AVMetadataMachineReadableCodeObject] else { return }
        
        guard objects.count > 0 else {
            qrCodeDetectedDate = nil
            
            DispatchQueue.main.async {
                self.overlayLayer.path = nil
            }
            
            return
        }
        
        // Adjust overlay layer
        let overlayPath = createOverlayPath(from: qrCodes.first!)
        
        DispatchQueue.main.async {
            self.overlayLayer.path = overlayPath
        }
        
        // Stop if QR code is on screen for target interval
        if let lastDetected = qrCodeDetectedDate {
            let timePassed = abs(lastDetected.timeIntervalSinceNow)
            if timePassed > detectedTargetTimeInterval {
                DispatchQueue.main.async {
                    self.cameraController.stopSession()
                    
                    self.delegate?.qrCodeScanner(scanner: self, didScan: qrCodes.first!.stringValue)
                }
            }
        } else {
            qrCodeDetectedDate = Date()
        }
    }
}
