//
//  AppStrings.swift
//  Codegen
//
//  Created by Chris Amanse on 12/26/16.
//
//

public enum AppStrings {
    public static let cancel = "Cancel"
    public static let delete = "Delete"
    public static let scan = "Scan"
    public static let manual = "Manual"
    
    public enum Alerts {}
    public enum Licenses {}
}

public extension AppStrings.Alerts {
    public enum DeleteAll {
        public static let title = "Delete All"
        public static let message = "Are you sure you want to delete all accounts?"
    }
    
    public enum AddAccountFailed {
        public static let title = "Add Account Failed"
        public static let unknownError = "UnknownError"
        public static let fixMessage = "Please fix the following errors:"
    }
    
    public enum QRCodeError {
        public static let title = "QR Code Error"
        public static let message = "Invalid code. Try adding manually if possible."
    }
    
    public enum CameraError {
        public static let title = "Camera Error"
        public static let message = "Failed to open camera."
    }
    
    public enum ImportFailed {
        public static let title = "Import Failed"
        public static let message = "Failed to import accounts."
    }
}

public extension AppStrings.Licenses {
    public static let all = ["CryptoKit", "OTPKit", "QRSwift", "Realm"]
}
