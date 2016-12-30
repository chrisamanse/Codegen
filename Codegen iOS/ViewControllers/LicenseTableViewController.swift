//
//  LicenseTableViewController.swift
//  Codegen
//
//  Created by Chris Amanse on 12/29/16.
//
//

import UIKit

public class LicenseTableViewController: UITableViewController {
    private static let cellIdentifier = "BasicCell"
    private static let estimatedRowHeight: CGFloat = 200
    
    var licenseText: String {
        didSet {
            if isViewLoaded {
                tableView.reloadData()
            }
        }
    }
    
    public init(licenseText: String) {
        self.licenseText = licenseText
        
        super.init(style: .grouped)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.licenseText = ""
        
        super.init(coder: aDecoder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = LicenseTableViewController.estimatedRowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = dequeueCell()
        
        cell.textLabel?.text = licenseText
        
        return cell
    }
    
    private func dequeueCell() -> UITableViewCell {
        let identifier = LicenseTableViewController.cellIdentifier
        
        if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: identifier) {
            return dequeuedCell
        }
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
        
        cell.textLabel?.numberOfLines = 0
        
        return cell
    }
}
