//
//  AccountTableViewCell.swift
//  Codegen
//
//  Created by Chris Amanse on 09/30/2016.
//
//

import UIKit

class AccountTableViewCell: UITableViewCell {
    
    @IBOutlet weak var issuerLabel: UILabel!
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var progressView: VerticalProgressView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
}
