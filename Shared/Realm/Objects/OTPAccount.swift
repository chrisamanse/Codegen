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
    
    func currentPassword() throws -> String {
        if timeBased {
            guard let period = self.period else {
                throw OTPAccountError.noPeriod
            }
            
            let currentTimeInterval = Date().timeIntervalSince1970
            return try TOTP.generate(key: key,
                                 timeInterval: currentTimeInterval,
                                 period: period,
                                 digits: UInt(digits),
                                 hashFunction: hashFunction)
        } else {
            guard let counter = self.counter else {
                throw OTPAccountError.noCounter
            }
            
            return try HOTP.generate(key: key,
                                     counter: counter,
                                     digits: UInt(digits),
                                     hashFunction: hashFunction)
        }
    }
    
    override class func primaryKey() -> String {
        return "id"
    }
}

enum OTPAccountError: Error {
    case noPeriod
    case noCounter
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
