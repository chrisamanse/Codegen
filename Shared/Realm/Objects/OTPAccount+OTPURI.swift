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
            // Period
            if let value = uri.parameters[OTPURI.Keys.period], let interval = TimeInterval(value) {
                self.period = interval
            } else {
                self.period = Defaults.period
            }
            
            self.timeBased = true
        case OTPURI.Types.hotp:
            // Counter
            guard let value = uri.parameters[OTPURI.Keys.counter], let counter = UInt64(value) else {
                return nil
            }
            
            self.counter = counter
            
            self.timeBased = false
        default:
            return nil
        }
        
        // HashFunction
        if let algorithm = uri.parameters[OTPURI.Keys.algorithm]?.lowercased(), let hash = HashFunction(rawValue: algorithm) {
            self.hashFunction = hash
        } else {
            self.hashFunction = Defaults.hashFunction
        }
        
        // Digits
        if let value = uri.parameters[OTPURI.Keys.digits], let intValue = Int(value) {
            self.digits = intValue
        } else {
            self.digits = Defaults.digits
        }
        
        // Issuer and Account
        let labelComponents = uri.label.components(separatedBy: ":")
        if labelComponents.count > 1 {
            // Has prefixed issuer
            self.issuer = labelComponents[0]
            self.account = labelComponents.dropFirst().joined(separator: ":")
        } else {
            // If no prefixed issuer, find it in parameters
            if let issuer = uri.parameters[OTPURI.Keys.issuer] {
                self.issuer = issuer
            }
            
            // Label is account
            self.account = uri.label
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
        
        if let period = self.period, timeBased {
            parameters[OTPURI.Keys.period] = String(describing: period)
        } else if let counter = self.counter, !timeBased {
            parameters[OTPURI.Keys.counter] = String(describing: counter)
        }
        
        parameters[OTPURI.Keys.secret] = Base32.encode(key)
        parameters[OTPURI.Keys.digits] = String(describing: digits)
        
        return OTPURI(type: type, label: label, parameters: parameters)
    }
}
