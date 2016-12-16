//
//  OTPURI.swift
//  Codegen
//
//  Created by Chris Amanse on 09/29/2016.
//
//

import Foundation

extension String {
    var urlQueryParameterSafe: String? {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryParameterAllowed)
    }
    
    var urlSafe: String {
        return urlQueryParameterSafe ?? self
    }
}

extension CharacterSet {
    static var urlQueryParameterAllowed: CharacterSet {
        return self.init(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-._~/?")
    }
}

public struct OTPURI {
    public struct Keys {
        public static var    scheme: String { return "otpauth" }
        public static var    secret: String { return "secret" }
        public static var    issuer: String { return "issuer" }
        public static var algorithm: String { return "algorithm" }
        public static var    digits: String { return "digits" }
        public static var   counter: String { return "counter" }
        public static var    period: String { return "period" }
    }
    
    public var url: URL? {
        var urlString = Keys.scheme + "://" + type.urlSafe + "/" + label.urlSafe
        
        let parameterStrings = parameters.map { $0.urlSafe + "=" + $1.urlSafe }
        
        if parameterStrings.count > 0 {
            urlString += "?" + parameterStrings.joined(separator: "&")
        }
        
        return URL(string: urlString)
    }
    
    public let type: String
    
    public let label: String
    
    public let parameters: [String: String]
    
    public init?(url: URL) {
        guard url.scheme == Keys.scheme else {
            return nil
        }
        guard let type = url.host else {
            return nil
        }
        guard let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            return nil
        }
        
        var parameters: [String: String] = [:]
        
        queryItems.forEach { parameters[$0.name] = $0.value }
        
        self.type = type
        self.label = url.lastPathComponent
        self.parameters = parameters
    }
    
    public init?(uriString: String) {
        guard let url = URL(string: uriString) else { return nil }
        
        self.init(url: url)
    }
}

// Equatable

extension OTPURI: Equatable {
    public static func ==(lhs: OTPURI, rhs: OTPURI) -> Bool {
        return lhs.parameters == rhs.parameters && lhs.type == rhs.type && lhs.label == rhs.label
    }
}

