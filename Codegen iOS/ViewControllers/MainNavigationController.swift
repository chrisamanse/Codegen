//
//  MainNavigationController.swift
//  Codegen
//
//  Created by Chris Amanse on 12/23/16.
//
//

import UIKit

class MainNavigationController: UINavigationController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if topViewController is ExportViewController {
            return .portrait
        }
        
        return super.supportedInterfaceOrientations
    }
}
