//
//  OTPAccountStore.swift
//  Codegen
//
//  Created by Chris Amanse on 10/01/2016.
//
//

import Foundation
import RealmSwift

class OTPAccountStore: Object {
    let accounts = List<OTPAccount>()
    
    static func defaultStore(in realm: Realm) throws -> OTPAccountStore {
        print("defaultStore")
        // Fetch store
        let result = realm.objects(self)
        
        if let store = result.first {
            return store
        }
        
        // Create first and only store
        let store = OTPAccountStore()
        
        try realm.write {
            realm.add(store)
        }
        
        return store
    }
}
