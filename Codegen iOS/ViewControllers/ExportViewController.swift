//
//  ExportViewController.swift
//  Codegen
//
//  Created by Chris Amanse on 12/19/16.
//
//

import UIKit
import QRSwift

class ExportViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var accounts: [OTPAccount] = [] {
        didSet {
            guard isViewLoaded else { return }
            
            createQRCodes()
        }
    }
    
    let separator = ";"
    
    var qrCodes: [UIImage?] = []
    let qrCodeSize = CGSize(width: 280, height: 280)
    var currentQRCodeIndex = 0
    
    var timer: Timer?
    var qrCodeChangeInterval: TimeInterval = 0.25
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createQRCodes()
        
        if qrCodes.count > 1 {
            createTimer()
        }
    }
    
    deinit {
        destroyTimer()
    }
    
    func createTimer() {
        guard self.timer == nil else {
            return
        }
        
        let timer = Timer(fire: Date(), interval: qrCodeChangeInterval, repeats: true) { [unowned self] timer in
            self.incrementQRCodeIndex()
            
            self.imageView.image = self.qrCodes[self.currentQRCodeIndex]
        }
        
        RunLoop.main.add(timer, forMode: .commonModes)
        
        self.timer = timer
    }
    
    func destroyTimer() {
        timer?.invalidate()
        
        timer = nil
    }
    
    fileprivate func incrementQRCodeIndex() {
        if currentQRCodeIndex < qrCodes.count - 1 {
            currentQRCodeIndex += 1
        } else {
            currentQRCodeIndex = 0
        }
    }
    
    fileprivate func createExportStrings() -> [String] {
        var strings = [String]()
        
        let count = accounts.count
        
        for (index, account) in accounts.enumerated() {
            let string = [String(describing: index), String(describing: count), account.uri.uriString ].joined(separator: separator)
            
            strings.append(string)
        }
        
        return strings
    }
    
    fileprivate func createQRCodes() {
        let strings = createExportStrings()
        
        print(strings)
        
        let exportData = strings.lazy.map { $0.data(using: .utf8) }
        
        let generator = QRCodeGenerator()
        
        qrCodes = exportData.map { data -> UIImage? in
            guard let d = data, let ciImage = try? generator.outputImage(message: d, correctionLevel: .M, size: qrCodeSize) else {
                return nil
            }
            
            return UIImage(ciImage: ciImage)
        }
        
        if let first = qrCodes.first {
            self.imageView.image = first
        }
    }
}
