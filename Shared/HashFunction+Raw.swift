//
//  HashFunction+Raw.swift
//  Codegen
//
//  Created by Chris Amanse on 09/29/2016.
//
//

import Foundation
import CryptoKit

extension HashFunction: RawRepresentable {
    public init?(rawValue: String) {
        let hash: HashFunction? = {
            switch rawValue {
            case    "md5": return .md5
            case   "sha1": return .sha1
            case "sha224": return .sha224
            case "sha256": return .sha256
            case "sha384": return .sha384
            case "sha512": return .sha512
            default      : return nil
            }
        }()
        
        if let h = hash {
            self = h
        } else {
            return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case    HashFunction.md5: return "md5"
        case   HashFunction.sha1: return "sha1"
        case HashFunction.sha224: return "sha224"
        case HashFunction.sha256: return "sha256"
        case HashFunction.sha384: return "sha384"
        case HashFunction.sha512: return "sha512"
        default                 : return "" // Unexpected hash function, set raw to ""
        }
    }
}
