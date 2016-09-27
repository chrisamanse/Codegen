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



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        // Setup Realm
        do {
            try RealmDefaults.setupDefaultRealmConfiguration()
            
            // Inspect key
            guard let key = Realm.Configuration.defaultConfiguration.encryptionKey else {
                fatalError("No key found!")
            }
            
            let hexString = key.map {
                String(format: "%02x", $0)
                }.joined()
            
            print("Key data: \(hexString)")
            
            // Try to create a Realm (initializes Realm files)
            let realm = try Realm()
            
            // Ensure default Realm has key
            if realm.configuration.encryptionKey != key {
                fatalError("Different keys used!")
            }
        } catch let error {
            fatalError("Failed to generate RealmKey!: \(error)")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

