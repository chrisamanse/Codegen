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
    var scanner: QRCodeScanner?
    
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
    
    func startScanning() {
        do {
            try scanner?.startScanning()
        } catch let error {
            print("Scanner startScanning() error: \(error)")
            
            presentErrorAlert(title: "Camera Error", message: "Failed to open camera.") { _ in
                self.dismiss(animated: true)
            }
        }
    }
    
    func createScanner() {
        let scanner = QRCodeScanner(previewLayer: self.view.layer, overlayColor: UIColor.green.cgColor)
        scanner.delegate = self
        
        self.scanner = scanner
        
        startScanning()
    }
}

extension ScanViewController: QRCodeScannerDelegate {
    func qrCodeScanner(scanner: QRCodeScanner, didScan value: String) {
        scanner.stopScanning()
        
        print("QR Code: \(value)")
        
        guard let uri = OTPURI(uriString: value), let account = OTPAccount(uri: uri) else {
            presentErrorAlert(title: "QR Code Error", message: "Invalid code. Try adding manually if possible.") { _ in
                self.startScanning()
            }
            
            return
        }
        
        do {
            let realm = try Realm()
            let store = try OTPAccountStore.defaultStore(in: realm)
            
            try realm.write {
                store.accounts.insert(account, at: 0)
            }
            
            dismiss(animated: true)
        } catch let error {
            print("Failed to add: \(error)")
            
            presentErrorAlert(title: "Failed to Add", message: "Unknown error.") { _ in
                self.startScanning()
            }
        }
    }
}
