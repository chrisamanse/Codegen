//
//  Collection+Split.swift
//  Codegen
//
//  Created by Chris Amanse on 10/01/2016.
//
//

import Foundation

public extension Collection where Index: Strideable, IndexDistance == Index.Stride {
    public func split(by length: IndexDistance) -> [SubSequence] {
        return stride(from: startIndex, to: endIndex, by: length).map {
            self[$0 ..< (self.index($0, offsetBy: length, limitedBy: endIndex) ?? endIndex)]
        }
    }
    
    public func splitFromEnd(by length: IndexDistance) -> [SubSequence] {
        return stride(from: endIndex, to: startIndex, by: -length).map {
            self[(self.index($0, offsetBy: -length, limitedBy: startIndex) ?? startIndex) ..< $0]
            }.reversed()
    }
}

public extension String {
    public func split(by length: IndexDistance) -> [String] {
        return Array(self.characters).lazy.split(by: length).map { String($0) }
    }
    public func splitFromEnd(by length: IndexDistance) -> [String] {
        return Array(self.characters).lazy.splitFromEnd(by: length).map { String($0) }
    }
}
