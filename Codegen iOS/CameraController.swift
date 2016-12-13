//
//  CameraController.swift
//  Codegen
//
//  Created by Chris Amanse on 12/7/16.
//
//

import Foundation
import AVFoundation

public final class CameraController {
    public let captureDevice: AVCaptureDevice
    public var captureSession: AVCaptureSession?
    
    public var isTorchActive: Bool {
        guard captureDevice.hasTorch else {
            return false
        }
        
        return captureDevice.isTorchActive
    }
    
    public init() {
        captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    }
    
    deinit {
        stopSession()
    }
    
    public func turnTorch(on: Bool) throws -> Bool {
        guard captureDevice.hasTorch && captureDevice.isTorchAvailable else {
            return false
        }
        
        try captureDevice.lockForConfiguration()
        defer {
            captureDevice.unlockForConfiguration()
        }
        
        captureDevice.torchMode = on ? .on : .off
        
        return captureDevice.isTorchActive
    }
    
    @discardableResult
    public func startSession(metadataObjectTypes: [Any], delegate: AVCaptureMetadataOutputObjectsDelegate? = nil) throws -> AVCaptureSession {
        let input = try AVCaptureDeviceInput(device: captureDevice)
        let output = AVCaptureMetadataOutput()
        
        let session = AVCaptureSession()
        session.addInput(input)
        session.addOutput(output)
        
        let queue = DispatchQueue(label: "CameraController.MetadataObjectsQueue", attributes: [])
        
        output.setMetadataObjectsDelegate(delegate, queue: queue)
        output.metadataObjectTypes = metadataObjectTypes
        
        session.startRunning()
        
        captureSession = session
        return session
    }
    
    public func stopSession() {
        captureSession?.stopRunning()
        captureSession = nil
    }
}
