//
//  KeychainGenericPassword.swift
//  Codegen
//
//  Created by Chris Amanse on 09/27/2016.
//
//

import Foundation
import Security

public protocol KeychainGenericPassword {
    var service: String { get }
    var account: String { get }
    var key: Data { get }
    
    var accessibility: Keychain.Accessibility? { get }
    
    init(service: String, account: String, key: Data, accessibility: Keychain.Accessibility?)
}

public extension KeychainGenericPassword {
    public var accessibility: Keychain.Accessibility? {
        return .whenUnlocked
    }
    
    public init(fromKeychainWithService service: String, account: String, accessGroup: String? = nil) throws {
        let attributes = try Self.fetchAttributes(service: service, account: account, accessGroup: accessGroup)
        
        guard let data = attributes[kSecValueData as String] as? Data else {
                throw KeychainError.unexpectedPasswordData
        }
        
        let accessibility: Keychain.Accessibility?
        
        if let value = attributes[Keychain.Accessibility.key] as? String {
            accessibility = Keychain.Accessibility(value: value)
        } else {
            accessibility = nil
        }
        
        // Initialize
        self.init(service: service, account: account, key: data, accessibility: accessibility)
    }
    
    public func saveToKeychain(accessGroup: String? = nil) throws {
        do {
            // Check for an existing item in the keychain.
            try _ = Self.fetchAttributes(service: service, account: account, accessGroup: accessGroup)
            
            // Update the existing item with the new password.
            var attributesToUpdate: [String : AnyObject] = [
                (kSecValueData as String): self.key as AnyObject
            ]
            
            if let accessibility = self.accessibility {
                attributesToUpdate[Keychain.Accessibility.key] = accessibility.value as AnyObject
            }
            
            let query = Self.query(service: service, account: account, accessGroup: accessGroup)
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            
            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unexpectedStatus(status: status) }
        } catch KeychainError.noPassword {
            // No password was found in the keychain, create a dictionary to save as a new keychain item
            var newItem = Self.query(service: service, account: account, accessGroup: accessGroup)
            newItem[kSecValueData as String] = self.key as AnyObject
            
            if let accessibility = self.accessibility {
                newItem[Keychain.Accessibility.key] = accessibility.value as AnyObject
            }
            
            // Add a the new item to the keychain.
            let status = SecItemAdd(newItem as CFDictionary, nil)
            
            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unexpectedStatus(status: status) }
        }
    }
}

public extension KeychainGenericPassword {
    public static func query(service: String, account: String? = nil, accessGroup: String? = nil) -> [String: AnyObject] {
        var query = [String: AnyObject]()
        
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject
        
        if let account = account {
            query[kSecAttrAccount as String] = account as AnyObject
        }
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup as AnyObject
        }
        
        return query
    }
    
    public static func fetchAttributes(service: String, account: String?, accessGroup: String?) throws -> [String: AnyObject] {
        // Create query
        var query = self.query(service: service, account: account, accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        // Try to fetch
        var queryResult: AnyObject?
        
        let status = SecItemCopyMatching(query as CFDictionary, &queryResult)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.noPassword
        }
        guard status == noErr else {
            throw KeychainError.unexpectedStatus(status: status)
        }
        guard let result = queryResult as? [String: AnyObject] else {
            throw KeychainError.unexpectedItemData
        }
        
        return result
    }
}
