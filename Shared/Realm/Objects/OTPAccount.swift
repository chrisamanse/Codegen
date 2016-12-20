//
//  OTPAccount.swift
//  Codegen
//
//  Created by Chris Amanse on 09/27/2016.
//
//

import Foundation
import RealmSwift
import CryptoKit
import OTPKit

class OTPAccount: Object {
    dynamic var id: String = UUID().uuidString
    dynamic var issuer: String?
    dynamic var account: String = ""
    dynamic var key: Data = Data()
    dynamic var digits: Int = Defaults.digits
    dynamic var timeBased: Bool = false
    dynamic var period: TimeInterval = Defaults.period
    
    private dynamic var counterSigned = Defaults.counter.signed
    var counter: UInt64 {
        get {
            return counterSigned.unsigned
        }
        set {
            counterSigned = newValue.signed
        }
    }
    
    private dynamic var hashFunctionRaw: String = Defaults.hashFunction.rawValue
    var hashFunction: HashFunction {
        get {
            guard let hash = HashFunction(rawValue: hashFunctionRaw) else {
                return .sha1
            }
            
            return hash
        }
        set {
            let rawValue = newValue.rawValue
            
            if rawValue == "" {
                hashFunctionRaw = Defaults.hashFunction.rawValue
            } else {
                hashFunctionRaw = newValue.rawValue
            }
        }
    }
    
    var obfuscatedPassword: String {
        return String(repeating: "•", count: digits)
    }
    
    func currentPassword() throws -> String {
        if timeBased {
            let currentTimeInterval = Date().timeIntervalSince1970
            return try TOTP.generate(key: key,
                                 timeInterval: currentTimeInterval,
                                 period: period,
                                 digits: UInt(digits),
                                 hashFunction: hashFunction)
        } else {
            return try HOTP.generate(key: key,
                                     counter: counter,
                                     digits: UInt(digits),
                                     hashFunction: hashFunction)
        }
    }
    
    func formattedPassword(obfuscated: Bool = false) -> String {
        let password: String
        if obfuscated {
            password = obfuscatedPassword
        } else {
            password = (try? currentPassword()) ?? obfuscatedPassword
        }
        
        return password.split(by: 3).joined(separator: " ")
    }
    
    override class func primaryKey() -> String {
        return "id"
    }
    
    override class func ignoredProperties() -> [String] {
        return ["counter"]
    }
}

// Extension for 64-bit integer signed <-> unsigned conversion

public extension Int64 {
    var unsigned: UInt64 {
        let valuePointer = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate(capacity: 1)
        }
        
        valuePointer.pointee = self
        
        return valuePointer.withMemoryRebound(to: UInt64.self, capacity: 1) { $0.pointee }
    }
}

public extension UInt64 {
    var signed: Int64 {
        let valuePointer = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate(capacity: 1)
        }
        
        valuePointer.pointee = self
        
        return valuePointer.withMemoryRebound(to: Int64.self, capacity: 1) { $0.pointee }
    }
}
