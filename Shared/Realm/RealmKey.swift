//
//  RealmKey.swift
//  Codegen
//
//  Created by Chris Amanse on 09/27/2016.
//
//

import Foundation
import Security

enum RealmKey {
    static var `class`: CFString {
        return kSecClassKey
    }
    static var identifierData: Data {
        return "xyz.chrisamanse.codegen.realmKey".data(using: .utf8)!
    }
    static var keySizeInBits: Int {
        return 512
    }
    static var accessibility: CFString {
        return kSecAttrAccessibleAfterFirstUnlock
    }
    static var query: [String: AnyObject] {
        return [
            kSecClass as String: self.class as AnyObject,
            kSecAttrApplicationTag as String: self.identifierData as AnyObject,
            kSecAttrKeySizeInBits as String: self.keySizeInBits as AnyObject
        ]
    }
    
    static func fetchKey() throws -> Data {
        var fetchQuery: [String: AnyObject] = self.query
        fetchQuery[kSecReturnData as String] = kCFBooleanTrue
        
        // Fetch Keychain item
        var result: AnyObject?
        let status = SecItemCopyMatching(fetchQuery as CFDictionary, &result)
        
        // If found, return key
        if status == errSecSuccess {
            if let key = result as? Data {
                return key
            } else {
                throw RealmKeyError.unexpectedResult(status: status, result: result)
            }
        }
        
        // Not found, create Keychain item, if other error, throw error
        guard status == errSecItemNotFound else {
            print("Not errSecItemNotFound: \(errSecItemNotFound)")
            throw RealmKeyError.failedToFetchStoredKey(status: status)
        }
        
        // Generate random 512-bit key
        let key = try generateRandomKey()
        
        var newItem: [String: AnyObject] = self.query
        newItem[kSecValueData as String] = key as AnyObject
        newItem[kSecAttrAccessible as String] = self.accessibility as AnyObject
        
        let addStatus = SecItemAdd(newItem as CFDictionary, nil)
        
        guard addStatus == noErr else {
            throw RealmKeyError.failedToSaveGeneratedKey(status: addStatus)
        }
        
        return key
    }
    
    static func deleteKey() throws {
        let status = SecItemDelete(self.query as CFDictionary)
        
        if !(status == noErr || status == errSecItemNotFound) {
            throw RealmKeyError.failedToDeleteStoredKey(status: status)
        }
    }
    
    private static func generateRandomKey() throws -> Data {
        var key = Data(count: 64)
        
        // Get random bytes from /dev/random
        let flag = key.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 64, bytes)
        }
        
        guard flag == 0 else {
            throw RealmKeyError.failedToGenerateKey(error: errno)
        }
        
        return key
    }
}

enum RealmKeyError: Error {
    case unexpectedResult(status: OSStatus, result: AnyObject?)
    case failedToFetchStoredKey(status: OSStatus)
    case failedToSaveGeneratedKey(status: OSStatus)
    case failedToGenerateKey(error: Int32)
    
    case failedToDeleteStoredKey(status: OSStatus)
}
