//
//  OTPAccount.swift
//  Codegen
//
//  Created by Chris Amanse on 09/27/2016.
//
//

import Foundation
import RealmSwift

class OTPAccount: Object {
    dynamic var id: String = UUID().uuidString
    dynamic var issuer: String?
    dynamic var account: String = ""
    dynamic var key: Data?
    dynamic var digits: Int = 6
    
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
