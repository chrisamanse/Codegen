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
    private let appStoreURLString = "https://itunes.apple.com/us/app/codegen/id1156067090?mt=8"
    
    @IBAction func didPressDone(_ sender: AnyObject) {
        dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            showLicenses()
        case (0, 1):
            openURL(urlString: supportURLString)
        case (1, 0):
            openURL(urlString: appStoreURLString)
        default:
            break
        }
    }
    
    private func showLicenses() {
        let viewController = LicensesTableViewController(licenses: AppStrings.Licenses.all)
        
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func openURL(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        UIApplication.shared.open(url)
    }
}
