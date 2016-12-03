//
//  AddManualViewController+UITextFieldDelegate.swift
//  Codegen
//
//  Created by Chris Amanse on 12/3/16.
//
//

import UIKit

extension AddManualViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case issuerTextField:
            accountTextField.becomeFirstResponder()
        case accountTextField:
            keyTextField.becomeFirstResponder()
        case keyTextField:
            keyTextField.resignFirstResponder()
        default:
            return true
        }
        
        return false
    }
}
