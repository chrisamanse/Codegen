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

