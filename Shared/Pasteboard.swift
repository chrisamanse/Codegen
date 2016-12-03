//
//  Pasteboard.swift
//  Codegen
//
//  Created by Chris Amanse on 12/3/16.
//
//

import Foundation

#if os(macOS)
    import Cocoa
#elseif os(iOS)
    import UIKit
#endif

#if os(macOS)
    public typealias Pasteboard = NSPasteboard
#elseif os(iOS)
    public typealias Pasteboard = UIPasteboard
#endif

#if os(macOS)
    public extension NSPasteboard {
        public static var general: NSPasteboard {
            return general()
        }
        
        public var string: String? {
            get {
                return string(forType: NSPasteboardTypeString)
            }
            set {
                self.clearContents()
                
                if let value = newValue {
                    self.setString(value, forType: NSPasteboardTypeString)
                }
            }
        }
    }
#endif
