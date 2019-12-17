//
//  DPDHelper.swift
//  DPDSwift
//
//Created by Sylveus, Steeven on 11/8/18.
//

import UIKit

public typealias CompletionBlock =  (_ response: Any?, _ responseHeader: [AnyHashable: Any]?, _ error: Error?) -> Void

public class DPDHelper: NSObject {
    
    static let sharedHelper = DPDHelper()
    
    var networkReachable: Bool = true
    
    
    class func toJsonString(_ data: Any, prettyPrinted:Bool = false) -> String? {
        let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions(rawValue: 0)
        guard let jsonData: Data = try? JSONSerialization.data(withJSONObject: data, options: options) else {
            return nil
        }
        let jsonString: String? = String.init(data: jsonData, encoding: String.Encoding.utf8)
        return jsonString
    }
    
    class func writeArrayWithCustomObjToUserDefaults(_ key: String, array: [[String: Any]]) {
        let defaults = UserDefaults.standard
        let data = NSKeyedArchiver.archivedData(withRootObject: array)
        defaults.set(data, forKey: key)
        defaults.synchronize()
    }
    
    class func readArrayWithCustomObjFromUserDefault(_ key: String) -> [[String: AnyObject]]? {
        let defaults = UserDefaults.standard
        if let data = defaults.object(forKey: key) as? Data {
            if let dataArray = NSKeyedUnarchiver.unarchiveObject(with: data) as? [[String: AnyObject]] {
                return dataArray
            }
        }
        return nil
    }
    
    class func saveToUserDefault(_ key: String, value: AnyObject) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: key)
        defaults.synchronize()
    }
    
    class func removeFromUserDefault(_ key: String) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: key)
        defaults.synchronize()
    }
    
    class func retrieveFromUserDefault(_ key: String) -> AnyObject? {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: key) as AnyObject?
    }
    
    open class func getSessionId() -> String {
        if let token = DPDHelper.retrieveFromUserDefault(sessionTokenKey) as? String {
            return "sid=\(token)"
        }
        
        return ""
    }
    
    open class func getAccessToken() -> String {
        if let token = DPDCredentials.sharedCredentials.accessToken {
            return token
        }
        
        return ""
    }
}
