//
//  OTPAccount+OTPURL.swift
//  Codegen
//
//  Created by Chris Amanse on 09/29/2016.
//
//

import Foundation
import CryptoKit
import OTPKit

extension OTPAccount {
    convenience init?(uri: OTPURI) {
        self.init()
        
        switch uri.type.lowercased() {
        case OTPURI.Types.totp:
            period = uri.parameters[OTPURI.Keys.period].flatMap { TimeInterval($0) } ?? Defaults.period
            timeBased = true
        case OTPURI.Types.hotp:
            counter = uri.parameters[OTPURI.Keys.counter].flatMap { UInt64($0) } ?? Defaults.counter
            timeBased = false
        default:
            return nil
        }
        
        hashFunction = uri.parameters[OTPURI.Keys.algorithm].flatMap { HashFunction(rawValue: $0.lowercased()) } ?? Defaults.hashFunction
        digits = uri.parameters[OTPURI.Keys.digits].flatMap { Int($0) } ?? Defaults.digits
        
        // Issuer and Account
        let labelComponents = uri.label.components(separatedBy: ":")
        if labelComponents.count > 1 {
            // Has prefixed issuer
            issuer = labelComponents.first
            account = labelComponents.dropFirst().joined(separator: ":")
        } else {
            // If no prefixed issuer, find it in parameters
            issuer = uri.parameters[OTPURI.Keys.issuer]
            
            // Label is account
            account = uri.label
        }
        
        // Key
        guard let value = uri.parameters[OTPURI.Keys.secret], let data = try? Base32.decode(value) else {
            return nil
        }
        
        self.key = data
    }
    
    public var uri: OTPURI {
        let type = timeBased ? OTPURI.Types.totp : OTPURI.Types.hotp
        
        let noIssuer = issuer.map { $0.isEmpty } ?? true
        
        let label = noIssuer ? account : issuer! + ":" + account
        
        var parameters = [String: String]()
        
        if timeBased {
            parameters[OTPURI.Keys.period] = String(describing: period)
        } else {
            parameters[OTPURI.Keys.counter] = String(describing: counter)
        }
        
        parameters[OTPURI.Keys.secret] = Base32.encode(key)
        parameters[OTPURI.Keys.digits] = String(describing: digits)
        
        return OTPURI(type: type, label: label, parameters: parameters)
    }
}
