//
//  AppDelegate.swift
//  Codegen macOS
//
//  Created by Chris Amanse on 09/23/2016.
//
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var encrypted: Bool {
        return false
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Setup Realm
        AppRealm.shared.setup()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

