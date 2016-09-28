//
//  AppDelegate.swift
//  Codegen iOS
//
//  Created by Chris Amanse on 09/23/2016.
//
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Setup Realm
        do {
            try RealmDefaults.setupDefaultRealmConfiguration()
            
            // Inspect key
            guard let key = Realm.Configuration.defaultConfiguration.encryptionKey else {
                fatalError("No key found in default Realm.Configuration!")
            }
            
            #if DEBUG
                // Only print key when debugging
                print("Key: \(key.map { String(format: "%02x", $0) }.joined())")
            #endif
            
            // Try to create a Realm (initializes Realm files if not yet initialized)
            _ = try Realm()
            
        } catch let error as RealmKeyError {
            switch error {
            case .failedToFetchStoredKey(status: let status):
                fatalError("Failed to fetch stored key: \(status)")
            case .failedToSaveGeneratedKey(status: let status):
                fatalError("Failed to save generated key: \(status)")
            case .failedToGenerateKey(error: let error):
                fatalError("Failed to generate key: \(error)")
            case .unexpectedResult(status: let status, result: let result):
                fatalError("Unexpected fetch result: \(result)\n\nStatus: \(status)")
            case .failedToDeleteStoredKey(status: let status):
                fatalError("Failed to delete stored key: \(status)")
            }
        } catch let error as Realm.Error {
            fatalError("Realm error: \(error)")
        } catch let error {
            fatalError("Failed to setup Realm: \(error)")
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

