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
        static var       digits: Int { return 6 }
        static var hashFunction: HashFunction { return .sha1 }
        static var       period: TimeInterval { return 30 }
    }
}
