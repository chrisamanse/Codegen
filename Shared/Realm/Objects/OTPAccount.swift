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

class OTPAccount: Object {
    dynamic var id: String = UUID().uuidString
    dynamic var issuer: String?
    dynamic var account: String = ""
    dynamic var key: Data?
    dynamic var digits: Int = 6
    
    private dynamic var hashFunctionRaw: String = "sha1"
    var hashFunction: HashFunction {
        get {
            switch hashFunctionRaw {
            case    "md5": return .md5
            case   "sha1": return .sha1
            case "sha224": return .sha224
            case "sha256": return .sha256
            case "sha384": return .sha384
            case "sha512": return .sha512
            default      :
                // Unexpected raw hash function, set raw to "sha1"
                hashFunctionRaw = "sha1"
                return .sha1
            }
        }
        set {
            let raw: String
            switch newValue {
            case    HashFunction.md5: raw = "md5"
            case   HashFunction.sha1: raw = "sha1"
            case HashFunction.sha224: raw = "sha224"
            case HashFunction.sha256: raw = "sha256"
            case HashFunction.sha384: raw = "sha384"
            case HashFunction.sha512: raw = "sha512"
            default                 : raw = "sha1" // Unexpected hash function, set raw to "sha1"
            }
            
            hashFunctionRaw = raw
        }
    }
    
    dynamic var timeBased: Bool = false
    
    private let counterStored = RealmOptional<Int64>()
    var counter: UInt64? {
        get {
            guard let value = counterStored.value else {
                return nil
            }
            
            return value.unsigned
        }
        set {
            counterStored.value = newValue?.signed
        }
    }
    
    private let periodStored = RealmOptional<TimeInterval>()
    var period: TimeInterval? {
        get {
            return periodStored.value
        }
        set {
            periodStored.value = newValue
        }
    }
    
    override class func primaryKey() -> String {
        return "id"
    }
}

// Extension for 64-bit integer signed <-> unsigned conversion

fileprivate extension Int64 {
    var unsigned: UInt64 {
        let valuePointer = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate(capacity: 1)
        }
        
        valuePointer.pointee = self
        
        return valuePointer.withMemoryRebound(to: UInt64.self, capacity: 1) { $0.pointee }
    }
}

fileprivate extension UInt64 {
    var signed: Int64 {
        let valuePointer = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        defer {
            valuePointer.deallocate(capacity: 1)
        }
        
        valuePointer.pointee = self
        
        return valuePointer.withMemoryRebound(to: Int64.self, capacity: 1) { $0.pointee }
    }
}
