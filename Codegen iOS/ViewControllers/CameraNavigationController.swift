//
//  CameraNavigationController.swift
//  Codegen
//
//  Created by Chris Amanse on 12/15/16.
//
//

import UIKit

class CameraNavigationController: UINavigationController {
    var progressView: UIProgressView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isHidden = true
        
        view.addSubview(progressView)
        
        let bottom = NSLayoutConstraint(item: progressView, attribute: .bottom, relatedBy: .equal, toItem: navigationBar, attribute: .bottom, multiplier: 1, constant: -1)
        let left = NSLayoutConstraint(item: progressView, attribute: .leading, relatedBy: .equal, toItem: navigationBar, attribute: .leading, multiplier: 1, constant: 0)
        let right = NSLayoutConstraint(item: progressView, attribute: .trailing, relatedBy: .equal, toItem: navigationBar, attribute: .trailing, multiplier: 1, constant: 0)
        
        view.addConstraints([bottom, left, right])
        
        self.progressView = progressView
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
