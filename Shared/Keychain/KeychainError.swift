//
//  KeychainError.swift
//  Codegen
//
//  Created by Chris Amanse on 09/24/2016.
//
//

import Foundation

public enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unexpectedItemData
    case unexpectedStatus(status: OSStatus)
}
