//
//  OTPAccount.Defaults.Swift
//  Codegen
//
//  Created by Chris Amanse on 09/29/2016.
//
//

import Foundation
import CryptoKit

extension OTPAccount {
    enum Defaults {
        static var digits: Int = 6
        static var hashFunction: HashFunction = .sha1
        static var period: TimeInterval = 30
        static var counter: UInt64 = 1
    }
}
