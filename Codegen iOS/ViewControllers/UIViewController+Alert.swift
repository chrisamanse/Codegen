//
//  UIViewController+Alert.swift
//  Codegen
//
//  Created by Chris Amanse on 12/15/16.
//
//

import UIKit

extension UIViewController {
    func presentErrorAlert(title: String, message: String, okTitle: String = "OK", okHandler: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: okTitle, style: .default, handler: okHandler)
        
        alertController.addAction(okAction)
        
        present(alertController, animated: true)
    }
}
