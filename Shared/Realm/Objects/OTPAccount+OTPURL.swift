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
    convenience init?(url: OTPURL) {
        self.init()
        
        switch url.type.lowercased() {
        case "totp":
            // Period
            if let value = url.parameters[OTPURL.Keys.period], let interval = TimeInterval(value) {
                self.period = interval
            } else {
                self.period = 30
            }
            
            self.timeBased = true
        case "hotp":
            // Counter
            guard let value = url.parameters[OTPURL.Keys.counter], let counter = UInt64(value) else {
                return nil
            }
            
            self.counter = counter
            
            self.timeBased = false
        default:
            return nil
        }
        
        // HashFunction
        if let algorithm = url.parameters[OTPURL.Keys.algorithm]?.lowercased(), let hash = HashFunction(rawValue: algorithm) {
            self.hashFunction = hash
        } else {
            self.hashFunction = .sha1
        }
        
        // Digits
        if let value = url.parameters[OTPURL.Keys.digits], let intValue = Int(value) {
            self.digits = intValue
        } else {
            self.digits = 6
        }
        
        // Issuer and Account
        let labelComponents = url.label.components(separatedBy: ":")
        if labelComponents.count > 1 {
            // Has prefixed issuer
            self.issuer = labelComponents[0]
            self.account = labelComponents.dropFirst().joined(separator: ":")
        } else {
            // If no prefixed issuer, find it in parameters
            if let issuer = url.parameters[OTPURL.Keys.issuer] {
                self.issuer = issuer
            }
            
            // Label is account
            self.account = url.label
        }
        
        // Key
        guard let value = url.parameters[OTPURL.Keys.secret], let data = try? Base32.decode(value) else {
            return nil
        }
        
        self.key = data
    }
}
