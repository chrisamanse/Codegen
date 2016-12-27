//
//  ScanViewController.swift
//  Codegen
//
//  Created by Chris Amanse on 12/7/16.
//
//

import UIKit
import RealmSwift

class ScanViewController: UIViewController {
    @IBOutlet weak var cameraPreview: UIView!
    
    var scanner: QRCodeScanner?
    
    var imports = [Int: String]()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scanner?.setPreviewLayerNeedsUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        createScanner()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        scanner?.stopScanning()
    }
    
    @IBAction func didPressCancel(_ sender: AnyObject) {
        dismiss(animated: true)
    }
    
    func startScanning(continuous: Bool = false) {
        do {
            try scanner?.startScanning(continuous: continuous)
        } catch let error {
            print("Scanner startScanning() error: \(error)")
            
            presentErrorAlert(title: AppStrings.Alerts.CameraError.title, message: AppStrings.Alerts.CameraError.message) { _ in
                self.dismiss(animated: true)
            }
        }
    }
    
    func createScanner() {
        let scanner = QRCodeScanner(previewLayer: self.cameraPreview.layer, overlayColor: UIColor.green.cgColor)
        scanner.delegate = self
        
        self.scanner = scanner
        
        startScanning()
    }
}

extension ScanViewController: QRCodeScannerDelegate {
    func qrCodeScanner(scanner: QRCodeScanner, didScan value: String) {
        if scanner.continuous {
            guard let components = parse(importString: value) else {
                print("Not an import string")
                return
            }
            
            foundImport(index: components.index, uriString: components.uriString)
            
            DispatchQueue.main.async { [unowned self] in
                let progress = self.importProgress(count: components.count)
                self.progressView?.setProgress(progress, animated: true)
            }
            
            if imports.count == components.count {
                scanner.stopScanning()
                
                print("Found all imports: \(imports)")
                
                DispatchQueue.main.async { [unowned self] in
                    self.saveImports()
                }
            }
        } else {
            if let uri = OTPURI(uriString: value), let account = OTPAccount(uri: uri) {
                found(account: account)
            } else if let components = parse(importString: value) {
                print("Found Import String")
                
                imports = [:]
                
                let feedbackGenerator = UIImpactFeedbackGenerator()
                feedbackGenerator.prepare()
                
                foundImport(index: components.index, uriString: components.uriString)
                
                DispatchQueue.main.async { [unowned self] in
                    self.progressView?.isHidden = false
                    self.progressView?.progress = self.importProgress(count: components.count)
                }
                
                feedbackGenerator.impactOccurred()
                startScanning(continuous: true)
            } else {
                let feedbackGenerator = UINotificationFeedbackGenerator()
                
                feedbackGenerator.prepare()
                
                feedbackGenerator.notificationOccurred(.error)
                
                presentErrorAlert(title: AppStrings.Alerts.QRCodeError.title, message: AppStrings.Alerts.QRCodeError.message) { _ in
                    self.startScanning()
                }
            }
        }
    }
    
    private func found(account: OTPAccount) {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        
        feedbackGenerator.prepare()
        
        do {
            let realm = try Realm()
            let store = try OTPAccountStore.defaultStore(in: realm)
            
            try realm.write {
                store.accounts.insert(account, at: 0)
            }
            
            feedbackGenerator.notificationOccurred(.success)
            
            dismiss(animated: true)
        } catch let error {
            print("Failed to add: \(error)")
            
            feedbackGenerator.notificationOccurred(.error)
            
            presentErrorAlert(title: AppStrings.Alerts.AddAccountFailed.title, message: AppStrings.Alerts.AddAccountFailed.unknownError) { _ in
                self.startScanning()
            }
        }
    }
    
    private func parse(importString: String) -> (index: Int, count: Int, uriString: String)? {
        let components = importString.components(separatedBy: ";")
        
        guard components.count >= 3 else {
            return nil
        }
        
        guard let index = Int(components[0]), let count = Int(components[1]) else {
            return nil
        }
        
        return (index: index, count: count, uriString: components.dropFirst(2).joined(separator: ";"))
    }
    
    private func foundImport(index: Int, uriString: String) {
        guard imports[index] == nil else { return }
        
        imports[index] = uriString
    }
    
    private func saveImports() {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.prepare()
        
        let uriStrings = (0 ..< imports.count).lazy.flatMap { self.imports[$0] }
        let accounts = uriStrings.flatMap { OTPURI(uriString: $0) }.flatMap { OTPAccount(uri: $0) }
        
        do {
            let realm = try Realm()
            let store = try OTPAccountStore.defaultStore(in: realm)
            
            try realm.write {
                for account in accounts.reversed() {
                    store.accounts.insert(account, at: 0)
                }
            }
            
            feedbackGenerator.notificationOccurred(.success)
            
            dismiss(animated: true)
        } catch let error {
            print("Failed to import accounts: \(error)")
            
            feedbackGenerator.notificationOccurred(.error)
            
            presentErrorAlert(title: AppStrings.Alerts.ImportFailed.title, message: AppStrings.Alerts.ImportFailed.message) { _ in
                self.startScanning()
            }
        }
    }
    
    private var progressView: UIProgressView? {
        return (navigationController as? CameraNavigationController)?.progressView
    }
    
    private func importProgress(count: Int) -> Float {
        return Float(imports.count) / Float(count)
    }
}
