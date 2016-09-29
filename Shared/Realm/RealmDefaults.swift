//
//  RealmDefaults.swift
//  Codegen
//
//  Created by Chris Amanse on 09/27/2016.
//
//

import Foundation
import RealmSwift

enum RealmDefaults {
    static var realmFilename: String {
        return "Codegen.realm"
    }
    
    static var realmDirectoryURL: URL {
        #if os(iOS) || os(tvOS) || os(watchOS)
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            
            return documentsURL.appendingPathComponent("Realm", isDirectory: true)
        #elseif os(macOS)
            let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "xyz.chrisamanse.macos.codegen"
            
            return applicationSupportURL
                .appendingPathComponent(bundleIdentifier, isDirectory: true)
                .appendingPathComponent("Realm", isDirectory: true)
        #endif
    }
    
    static func setupDefaultRealmConfiguration(encryptionKey: Data? = nil) throws {
        var config = Realm.Configuration.defaultConfiguration
        
        // Setup Realm directory
        try setupRealmDirectory()
        
        // Set URL for configuration
        let newURL = realmDirectoryURL.appendingPathComponent(realmFilename)
        config.fileURL = newURL
        
        // Set encryption key
        config.encryptionKey = encryptionKey
        
        Realm.Configuration.defaultConfiguration = config
    }
    
    private static func setupRealmDirectory() throws {
        // Create if doesn't exist
        if !FileManager.default.fileExists(atPath: realmDirectoryURL.path) {
            try FileManager.default.createDirectory(at: realmDirectoryURL, withIntermediateDirectories: true)
        }
        
        #if os(iOS) || os(tvOS) || os(watchOS)
            // Get attributes
            var attributes = try FileManager.default.attributesOfItem(atPath: realmDirectoryURL.path)
            
            attributes[FileAttributeKey.protectionKey] = FileProtectionType.completeUntilFirstUserAuthentication
            
            // Set attributes
            try FileManager.default.setAttributes(attributes, ofItemAtPath: realmDirectoryURL.path)
        #endif
    }
}
