//
//  AddManualViewController.swift
//  Codegen
//
//  Created by Chris Amanse on 10/09/2016.
//
//

import UIKit
import RealmSwift
import OTPKit

class AddManualViewController: UITableViewController {
    
    @IBOutlet weak var issuerTextField: UITextField!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var accountTextField: UITextField!
    
    @IBOutlet weak var keyTextField: UITextField!
    @IBOutlet weak var digitsLabel: UILabel!
    @IBOutlet weak var digitsStepper: UIStepper!
    @IBOutlet weak var timeBasedSwitch: UISwitch!
    
    let estimatedRowHeight: CGFloat = 50
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = estimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    @IBAction func didPressCancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func didPressAdd(_ sender: UIBarButtonItem) {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        
        feedbackGenerator.prepare()
        
        do {
            let account = try createOTPAccount()
            
            let realm = try Realm()
            let store = try OTPAccountStore.defaultStore(in: realm)
            
            try realm.write {
                store.accounts.insert(account, at: 0)
            }
            
            feedbackGenerator.notificationOccurred(.success)
            
            dismiss(animated: true)
        } catch let error as AddAccountInvalidInput {
            feedbackGenerator.notificationOccurred(.error)
            
            let alertMessage = AppStrings.Alerts.AddAccountFailed.fixMessage + "\n" + error.errorMessages.joined(separator: "\n")
            presentErrorAlert(title: AppStrings.Alerts.AddAccountFailed.title, message: alertMessage)
        } catch let error {
            print("Failed to add: \(error)")
            
            feedbackGenerator.notificationOccurred(.error)
            
            presentErrorAlert(title: AppStrings.Alerts.AddAccountFailed.title, message: AppStrings.Alerts.AddAccountFailed.unknownError)
        }
    }
    
    @IBAction func didChangeStepperValue(_ sender: UIStepper) {
        let digits = Int(sender.value)
        digitsLabel.text = String(digits)
        
        let dummyAccount = OTPAccount()
        dummyAccount.digits = digits
        
        codeLabel.text = dummyAccount.formattedPassword(obfuscated: true)
    }
    
    func createOTPAccount() throws -> OTPAccount {
        let account = accountTextField.text ?? ""
        let key = formatted(key: keyTextField.text ?? "")
        let data = try? Base32.decode(key)
        var errors: AddAccountInvalidInput = []
        
        if account.isEmpty {
            errors.insert(.noAccount)
        }
        
        if key.isEmpty {
            errors.insert(.noKey)
        }
        
        if data == nil {
            errors.insert(.invalidKey)
        }
        
        guard errors.isEmpty else {
            throw errors
        }
        
        let newAccount = OTPAccount()
        
        newAccount.account = account
        newAccount.issuer = issuerTextField.text ?? ""
        newAccount.digits = Int(digitsStepper.value)
        newAccount.key = data!
        
        if timeBasedSwitch.isOn {
            newAccount.timeBased = true
            newAccount.period = OTPAccount.Defaults.period
        } else {
            newAccount.counter = OTPAccount.Defaults.counter
        }
        
        return newAccount
    }
    
    func formatted(key: String) -> String {
        return key.components(separatedBy: .whitespaces).joined(separator: "").uppercased()
    }
}
