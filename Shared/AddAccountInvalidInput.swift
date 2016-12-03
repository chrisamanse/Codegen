//
//  AddAccountInvalidInput.swift
//  Codegen
//
//  Created by Chris Amanse on 12/3/16.
//
//

public struct AddAccountInvalidInput: OptionSet, Error {
    public var rawValue: UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    public static let noAccount  = AddAccountInvalidInput(rawValue: 1 << 0)
    public static let noKey      = AddAccountInvalidInput(rawValue: 1 << 1)
    public static let invalidKey = AddAccountInvalidInput(rawValue: 1 << 2)
    
    public var errorMessages: [String] {
        var messages = [String]()
        
        let noAccount  = self.contains(.noAccount)
        let noKey      = self.contains(.noKey)
        let invalidKey = self.contains(.invalidKey)
        
        switch (noAccount, noKey, invalidKey) {
        case (_, _, true):
            if noAccount {
                messages.append(ErrorMessages.noAccount)
            }
            
            messages.append(ErrorMessages.invalidKey)
        case (true, true, _):
            messages.append(ErrorMessages.noAccountAndKey)
        case (true, false, _):
            messages.append(ErrorMessages.noAccount)
        case (false, true, _):
            messages.append(ErrorMessages.noKey)
        default:
            break
        }
        
        return messages
    }
}

public extension AddAccountInvalidInput {
    public enum ErrorMessages {
        static let noAccount       = "Account is required."
        static let noKey           = "Key is required."
        static let invalidKey      = "Invalid key."
        static let noAccountAndKey = "Both account and key are required."
    }
}
