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
    
    public fileprivate(set) var continuous: Bool = false
    
    public init(previewLayer: CALayer, overlayColor: CGColor) {
        cameraController = CameraController()
        metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        
        self.previewLayer = previewLayer
        self.overlayColor = overlayColor
    }
    
    deinit {
        stopScanning()
    }
    
    public func startScanning(continuous: Bool = false) throws {
        self.continuous = continuous
        
        let session = try cameraController.startSession(metadataObjectTypes: metadataObjectTypes, delegate: self)
        
        addPreviewLayer(from: session)
    }
    
    public func stopScanning(removePreviewLayer: Bool = false) {
        qrCodeDetectedDate = nil
        
        cameraController.stopSession()
        
        if removePreviewLayer {
            self.removePreviewLayer()
        }
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
        
        overlayLayer.frame = previewLayer.frame
        overlayLayer.path = createOverlayStartPath(in: previewLayer.bounds)
        
        previewLayer.addSublayer(captureVideoPreviewLayer)
        previewLayer.addSublayer(overlayLayer)
        
        self.captureVideoPreviewLayer = captureVideoPreviewLayer
    }
    
    public func removePreviewLayer() {
        overlayLayer.path = nil
        overlayLayer.removeFromSuperlayer()
        overlayLayer.removeAnimation(forKey: "path")
        
        captureVideoPreviewLayer?.removeFromSuperlayer()
        captureVideoPreviewLayer = nil
    }
    
    fileprivate func createPath<T: Collection>(fromCorners corners: T, rotated: Bool = false) -> CGPath where T.Iterator.Element == CGPoint, T.Index == Int, T.IndexDistance == Int {
        let path = CGMutablePath()
        
        path.move(to: corners.first!)
        
        let addLine: (Int) -> Void = {
            path.addLine(to: corners[$0])
        }
        
        let range = 1 ..< corners.count
        
        if rotated {
            range.forEach(addLine)
        } else {
            range.reversed().forEach(addLine)
        }
        
        addLine(0)
        
        return path
    }
    
    fileprivate func createOverlayStartPath(in rect: CGRect) -> CGPath {
        let size = CGSize(width: 280, height: 280)
        
        let origin = CGPoint(x: rect.midX - (size.width / 2),
                             y: rect.midY - (size.height / 2))
        
        let targetRect = CGRect(origin: origin, size: size)
        
        let corners = [
            CGPoint(x: targetRect.minX, y: targetRect.minY),
            CGPoint(x: targetRect.maxX, y: targetRect.minY),
            CGPoint(x: targetRect.maxX, y: targetRect.maxY),
            CGPoint(x: targetRect.minX, y: targetRect.maxY)
        ]
        
        return createPath(fromCorners: corners)
    }
    
    fileprivate func createOverlayAnimation(from object: AVMetadataMachineReadableCodeObject) -> CABasicAnimation {
        let code = captureVideoPreviewLayer!.transformedMetadataObject(for: object) as! AVMetadataMachineReadableCodeObject
        let cornersDictionaries = code.corners as! [[String: CGFloat]]
        let corners = cornersDictionaries.lazy.map {
            self.captureVideoPreviewLayer!.convert(CGPoint(x: $0["X"]!, y: $0["Y"]!), to: self.overlayLayer)
        }
        
        let endPath = createPath(fromCorners: corners, rotated: true)
        
        let animation = CABasicAnimation(keyPath: "path")
        animation.toValue = endPath
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.fillMode = kCAFillModeBoth
        animation.isRemovedOnCompletion = false
        
        return animation
    }
}

extension QRCodeScanner: AVCaptureMetadataOutputObjectsDelegate {
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        guard let objects = metadataObjects else { return }
        guard let qrCodes = objects as? [AVMetadataMachineReadableCodeObject] else { return }
        
        guard objects.count > 0 else {
            qrCodeDetectedDate = nil
            
            return
        }
        
        if continuous {
            // Keep scanning
            for code in qrCodes {
                delegate?.qrCodeScanner(scanner: self, didScan: code.stringValue ?? "")
            }
        } else {
            // Stop if QR code is on screen for target interval
            if let lastDetected = qrCodeDetectedDate {
                let timePassed = abs(lastDetected.timeIntervalSinceNow)
                if timePassed > detectedTargetTimeInterval {
                    stopScanning()
                    
                    let animation = createOverlayAnimation(from: qrCodes.first!)
                    
                    DispatchQueue.main.sync {
                        CATransaction.begin()
                        
                        CATransaction.setCompletionBlock {
                            self.delegate?.qrCodeScanner(scanner: self, didScan: qrCodes.first!.stringValue)
                        }
                        
                        overlayLayer.add(animation, forKey: animation.keyPath)
                        
                        CATransaction.commit()
                    }
                }
            } else {
                qrCodeDetectedDate = Date()
            }
        }
    }
}
