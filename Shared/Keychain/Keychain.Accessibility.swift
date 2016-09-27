//
//  Keychain.Accessibility.swift
//  Codegen
//
//  Created by Chris Amanse on 09/27/2016.
//
//

import Foundation
import Security

public extension Keychain {
    public struct Accessibility {
        public static var key = kSecAttrAccessible as String
        
        public var value: String
        
        public static var afterFirstUnlock = Accessibility(value: kSecAttrAccessibleAfterFirstUnlock as String)
        public static var afterFirstUnlockThisDeviceOnly = Accessibility(value: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
        public static var always = Accessibility(value: kSecAttrAccessibleAlways as String)
        public static var alwaysThisDeviceOnly = Accessibility(value: kSecAttrAccessibleAlwaysThisDeviceOnly as String)
        public static var whenPasscodeSetThisDeviceOnly = Accessibility(value: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly as String)
        public static var whenUnlocked = Accessibility(value: kSecAttrAccessibleWhenUnlocked as String)
        public static var whenUnlockedThisDeviceOnly = Accessibility(value: kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
    }
}

extension Keychain.Accessibility: Equatable {
    public static func ==(lhs: Keychain.Accessibility, rhs: Keychain.Accessibility) -> Bool {
        return lhs.value == rhs.value
    }
}
