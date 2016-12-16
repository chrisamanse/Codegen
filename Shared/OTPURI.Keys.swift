//
//  OTPURI.Keys.swift
//  Codegen
//
//  Created by Chris Amanse on 12/15/16.
//
//

import Foundation

public extension OTPURI {
    public struct Keys {
        public static var    scheme: String { return "otpauth" }
        public static var    secret: String { return "secret" }
        public static var    issuer: String { return "issuer" }
        public static var algorithm: String { return "algorithm" }
        public static var    digits: String { return "digits" }
        public static var   counter: String { return "counter" }
        public static var    period: String { return "period" }
    }
}
