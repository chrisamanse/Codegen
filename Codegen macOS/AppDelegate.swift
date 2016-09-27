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
                fatalError("No key found in default Realm.Configuration!")
            }
            
            #if DEBUG
                // Only print key when debugging
                print("Key: \(key.map { String(format: "%02x", $0) }.joined())")
            #endif
            
            // Try to create a Realm (initializes Realm files if not yet initialized)
            let realm = try Realm()
            
            // Ensure default Realm has the same key
            if realm.configuration.encryptionKey != key {
                fatalError("Unexpected key!")
            }
        } catch let error as RealmKeyError {
            switch error {
            case .failedToFetchStoredKey(status: let status):
                fatalError("Failed to fetch stored key: \(status)")
            case .failedToSaveGeneratedKey(status: let status):
                fatalError("Failed to save generated key: \(status)")
            case .failedToGenerateKey(error: let error):
                fatalError("Failed to generate key: \(error)")
            case .unexpectedResult(status: let status, result: let result):
                fatalError("Unexpected fetch result: \(result)\n\nStatus: \(status)")
            }
        } catch let error {
            fatalError("Failed to setup Realm: \(error)")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

