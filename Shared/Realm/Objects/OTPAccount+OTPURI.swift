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
    convenience init?(url: OTPURI) {
        self.init()
        
        switch url.type.lowercased() {
        case OTPURI.Types.totp:
            // Period
            if let value = url.parameters[OTPURI.Keys.period], let interval = TimeInterval(value) {
                self.period = interval
            } else {
                self.period = Defaults.period
            }
            
            self.timeBased = true
        case OTPURI.Types.hotp:
            // Counter
            guard let value = url.parameters[OTPURI.Keys.counter], let counter = UInt64(value) else {
                return nil
            }
            
            self.counter = counter
            
            self.timeBased = false
        default:
            return nil
        }
        
        // HashFunction
        if let algorithm = url.parameters[OTPURI.Keys.algorithm]?.lowercased(), let hash = HashFunction(rawValue: algorithm) {
            self.hashFunction = hash
        } else {
            self.hashFunction = Defaults.hashFunction
        }
        
        // Digits
        if let value = url.parameters[OTPURI.Keys.digits], let intValue = Int(value) {
            self.digits = intValue
        } else {
            self.digits = Defaults.digits
        }
        
        // Issuer and Account
        let labelComponents = url.label.components(separatedBy: ":")
        if labelComponents.count > 1 {
            // Has prefixed issuer
            self.issuer = labelComponents[0]
            self.account = labelComponents.dropFirst().joined(separator: ":")
        } else {
            // If no prefixed issuer, find it in parameters
            if let issuer = url.parameters[OTPURI.Keys.issuer] {
                self.issuer = issuer
            }
            
            // Label is account
            self.account = url.label
        }
        
        // Key
        guard let value = url.parameters[OTPURI.Keys.secret], let data = try? Base32.decode(value) else {
            return nil
        }
        
        self.key = data
    }
}
