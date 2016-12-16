//
//  ScanViewController.swift
//  Codegen
//
//  Created by Chris Amanse on 12/7/16.
//
//

import UIKit

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
    
    func createScanner() {
        let scanner = QRCodeScanner(previewLayer: self.view.layer, overlayColor: UIColor.green.cgColor)
        scanner.delegate = self
        
        self.scanner = scanner
        
        do {
            try scanner.startScanning()
        } catch let error {
            print("Scanner startScanning() error: \(error)")
            
            let alertController = UIAlertController(title: "Camera Error", message: "Failed to open camera.", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                self.dismiss(animated: true)
            }
            
            alertController.addAction(okAction)
            
            present(alertController, animated: true)
        }
    }
}

extension ScanViewController: QRCodeScannerDelegate {
    func qrCodeScanner(scanner: QRCodeScanner, didScan value: String) {
        scanner.stopScanning()
        
        print("QR Code: \(value)")
    }
}
