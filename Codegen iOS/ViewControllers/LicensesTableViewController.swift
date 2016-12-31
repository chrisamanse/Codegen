//
//  LicensesTableViewController.swift
//  Codegen
//
//  Created by Chris Amanse on 12/29/16.
//
//

import UIKit

public class LicensesTableViewController: UITableViewController {
    private static let cellIdentifier = "BasicCell"
    private static let estimatedRowHeight: CGFloat = 44
    private static let navigationBarTitle = "Licenses"
    
    public var licenses: [String] {
        didSet {
            if isViewLoaded {
                tableView.reloadData()
            }
        }
    }
    
    public init(licenses: [String]) {
        self.licenses = licenses
        
        super.init(style: .grouped)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.licenses = []
        
        super.init(coder: aDecoder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = LicensesTableViewController.navigationBarTitle
        
        tableView.estimatedRowHeight = LicensesTableViewController.estimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return licenses.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueCell()
        
        cell.textLabel?.text = licenses[indexPath.row]
        
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let licenseTitle = licenses[indexPath.row]
        let licenseText = LicenseFinder.licenseText(for: licenseTitle)
        
        let viewController = LicenseTableViewController(licenseText: licenseText)
        viewController.title = licenseTitle
        
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func dequeueCell() -> UITableViewCell {
        let identifier = LicensesTableViewController.cellIdentifier
        
        if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: identifier) {
            return dequeuedCell
        }
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
        
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
}

public extension LicensesTableViewController {
    public struct LicenseFinder {
        public static let `extension` = "license"
        public static let subdirectory = "Licenses"
        public static let noLicenseText = "No license found."
        
        public static func licenseText(for license: String) -> String {
            let url = Bundle.main.url(forResource: license, withExtension: self.extension, subdirectory: subdirectory)
            let licenseText = url.flatMap { try? String(contentsOf: $0) } ?? noLicenseText
            
            return licenseText
        }
        
        private init() {}
    }
}
