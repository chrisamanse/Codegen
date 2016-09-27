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
    
    static func setupDefaultRealmConfiguration() throws {
        var config = Realm.Configuration()
        
        // Compose URL for Realm directory
        let defaultURL = config.fileURL!
        let realmDirectory = defaultURL.deletingLastPathComponent().appendingPathComponent("Realm", isDirectory: true)
        
        // Setup file protection for Realm directory
        try setupFileProtection(atURL: realmDirectory)
        
        // Set URL for configuration
        let newURL = realmDirectory.appendingPathComponent(realmFilename)
        config.fileURL = newURL
        
        Realm.Configuration.defaultConfiguration = config
    }
    
    private static func setupFileProtection(atURL url: URL) throws {
        // Create if doesn't exist
        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        
        // Get attributes
        var attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        
        attributes[FileAttributeKey.protectionKey] = FileProtectionType.completeUntilFirstUserAuthentication
        
        // Set attributes
        try FileManager.default.setAttributes(attributes, ofItemAtPath: url.path)
    }
}
