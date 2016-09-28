//
//  AppDelegate.swift
//  Codegen macOS
//
//  Created by Chris Amanse on 09/23/2016.
//
//

import Cocoa
import RealmSwift

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var encrypted: Bool {
        return false
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        // Setup Realm
        do {
            #if DEBUG
                let key: Data? = encrypted ? try RealmKey.fetchKey() : nil
                
                if let k = key {
                    print("Key: \(k.map { String(format: "%02x", $0) }.joined())")
                } else {
                    print("Configuring unencrypted Realm...")
                }
            #else
                let key: Data? = try RealmKey.fetchKey()
            #endif
            
            try RealmDefaults.setupDefaultRealmConfiguration(encryptionKey: key)
            
            // Try to create a Realm (initializes Realm files if not yet initialized)
            _ = try Realm()
        } catch let error {
            fatalError("Failed to setup Realm: \(error)")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

