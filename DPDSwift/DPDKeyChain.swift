//
//  DPDKeyChain.swift
//  DPDSwift
//
//  Created by Steeven Sylveus on 12/26/19.
//  Copyright © 2019 Steeven Sylveus. All rights reserved.
//

import UIKit
import KeychainSwift

struct DPDKeyChain {
    static let keychain = KeychainSwift()
    
    static func save(_ key: String, value: String) {
        keychain.set(<#T##value: Bool##Bool#>, forKey: <#T##String#>, withAccess: KeychainSwiftAccessOptions?)
        keychain.set(value, forKey: key)
    }
    
    static func save(_ key: String, value: Bool) {
        keychain.set(value, forKey: key)
    }
    
    static func save(_ key: String, value: Data) {
        keychain.set(value, forKey: key)
    }
    
    static func getString(_ key: String) -> String? {
        return keychain.get(key)
    }
    
    static func getBool(_ key: String) -> Bool? {
        return keychain.getBool(key)
    }
    
    static func getData(_ key: String) -> Data? {
        return keychain.getData(key)
    }
    
    static func delete(_ key: String) {
        keychain.delete(key)
    }
    
    static func saveArray(_ key: String, array: [[String: Any]]) {
        let data = NSKeyedArchiver.archivedData(withRootObject: array)
        DPDKeyChain.save(key, value: data)
    }
    
    static func getArray(_ key: String) -> [[String: AnyObject]]? {
        if let data = DPDKeyChain.getData(key) {
            if let dataArray = NSKeyedUnarchiver.unarchiveObject(with: data) as? [[String: AnyObject]] {
                return dataArray
            }
        }
        return nil
    }
    
    static func clear() {
        keychain.clear()
    }
}
