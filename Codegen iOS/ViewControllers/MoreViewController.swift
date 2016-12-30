//
//  MoreViewController.swift
//  Codegen
//
//  Created by Chris Amanse on 12/29/16.
//
//

import UIKit

class MoreViewController: UITableViewController {
    @IBAction func didPressDone(_ sender: AnyObject) {
        dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            showLicenses()
        }
    }
    
    private func showLicenses() {
        let viewController = LicensesTableViewController(licenses: AppStrings.Licenses.all)
        
        navigationController?.pushViewController(viewController, animated: true)
    }
}
