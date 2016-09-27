//
//  RealmKey.swift
//  Codegen
//
//  Created by Chris Amanse on 09/27/2016.
//
//

import Foundation
import Security

struct RealmKey: KeychainGenericPassword {
    static var accessGroup: String? {
        return nil
    }
    
    static func fetchDefault() throws -> RealmKey {
        let service = "Codegen"
        let account = "RealmKey"
        let accessibility = Keychain.Accessibility.afterFirstUnlock
        
        do {
            // Return fetched account
            let fetchedAccount = try RealmKey(fromKeychainWithService: service, account: account, accessGroup: RealmKey.accessGroup)
            
            return fetchedAccount
        } catch KeychainError.noPassword {
            // Generate random key
            let key = try self.generateRandomKey()
            
            // Create new RealmKey
            let account = RealmKey(service: service, account: account, key: key, accessibility: accessibility)
            
            // Save to Keychain
            try account.saveToKeychain(accessGroup: self.accessGroup)
            
            // Return newly created account
            return account
        }
    }
    
    var service: String
    var account: String
    var key: Data
    
    var accessibility: Keychain.Accessibility?
    
    static func generateRandomKey() throws -> Data {
        // Create two random keys
        var key = Data(count: 64)
        var key2 = Data(count: 64)
        
        let flag = key.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 64, bytes)
        }
        
        let flag2 = key2.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 64, bytes)
        }
        
        guard flag == 0 && flag2 == 0 else {
            throw RealmKeyGenerationError.failedToGenerateKey(error: errno)
        }
        
        // XOR two random keys and use it as key
        var combinedBytes = [UInt8]()
        
        for index in 0 ..< key.count {
            let xored = key[index] ^ key2[index]
            
            combinedBytes.append(xored)
        }
        
        return Data(bytes: combinedBytes)
    }
    
    init(service: String, account: String, key: Data, accessibility: Keychain.Accessibility?) {
        self.service = service
        self.account = account
        self.key = key
        self.accessibility = accessibility
    }
}

enum RealmKeyGenerationError: Error {
    case failedToGenerateKey(error: Int32)
}
