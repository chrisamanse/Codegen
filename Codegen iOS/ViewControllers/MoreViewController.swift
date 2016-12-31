//
//  MoreViewController.swift
//  Codegen
//
//  Created by Chris Amanse on 12/29/16.
//
//

import UIKit

class MoreViewController: UITableViewController {
    private let supportURLString = "http://www.chrisamanse.xyz/"
    
    @IBAction func didPressDone(_ sender: AnyObject) {
        dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            showLicenses()
        } else if indexPath.row == 1 {
            openSupport()
        }
    }
    
    private func showLicenses() {
        let viewController = LicensesTableViewController(licenses: AppStrings.Licenses.all)
        
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func openSupport() {
        guard let url = URL(string: supportURLString) else {
            return
        }
        
        UIApplication.shared.open(url)
    }
}
