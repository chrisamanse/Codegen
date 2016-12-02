//
//  AddManualViewController.swift
//  Codegen
//
//  Created by Chris Amanse on 10/09/2016.
//
//

import UIKit
import RealmSwift

class AddManualViewController: UITableViewController {
    
    @IBOutlet weak var issuerTextField: UITextField!
    @IBOutlet weak var accountTextField: UITextField!
    
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
        do {
            guard let account = accountTextField.text, !account.isEmpty else {
                throw AddManualError.noAccount
            }
            
            let realm = try Realm()
            
            let issuer = issuerTextField.text ?? ""
            
            let newAccount = OTPAccount()
            newAccount.account = account
            newAccount.issuer = issuer
            newAccount.counter = 1
            
            let store = try OTPAccountStore.defaultStore(in: realm)
            
            try realm.write {
                store.accounts.insert(newAccount, at: 0)
            }
            
            dismiss(animated: true)
        } catch AddManualError.noAccount {
            presentErrorAlert(title: "Failed to Add", message: "Account can't be left blank.")
        } catch let error {
            print("Failed to add: \(error)")
            
            presentErrorAlert(title: "Failed to Add", message: "Unknown error.")
        }
    }
    
    func presentErrorAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alertController.addAction(okAction)
        
        present(alertController, animated: true)
    }
}

enum AddManualError: Error {
    case noAccount
}
