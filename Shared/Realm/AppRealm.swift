//
//  AppRealm.swift
//  Codegen
//
//  Created by Chris Amanse on 11/27/16.
//
//

import Foundation
import RealmSwift

public final class AppRealm {
    #if DEBUG
    public let encrypted = false
    #endif
    
    public static let shared = AppRealm()
    
    private init() {}
    
    public func setup() {
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
}
