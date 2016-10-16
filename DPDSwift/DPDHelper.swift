//
//  DPDHelper.swift
//  DPDSwift
//
//  Created by Steeven Sylveus (Contractor) on 10/16/16.
//  Copyright © 2016 Steeven Sylveus. All rights reserved.
//

import UIKit

typealias CompletionBlock =  (response: AnyObject?, responseHeader: [NSObject: AnyObject]?, error: NSError?) -> Void

public class DPDHelper: NSObject {

    static let sharedHelper = DPDHelper()
    
    var networkReachable: Bool = true
    
    class func toJsonString(data: AnyObject, prettyPrinted:Bool = false) -> String? {
        let options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : NSJSONWritingOptions(rawValue: 0)
        guard let jsonData: NSData = try? NSJSONSerialization.dataWithJSONObject(data, options: options) else {
            return nil
        }
        let jsonString: String? = String.init(data: jsonData, encoding: NSUTF8StringEncoding)
        return jsonString
    }
    
    class func writeArrayWithCustomObjToUserDefaults(key: String, array: [[String: AnyObject]]) {
        let defaults = NSUserDefaults.standardUserDefaults()
        let data = NSKeyedArchiver.archivedDataWithRootObject(array)
        defaults.setObject(data, forKey: key)
        defaults.synchronize()
    }
    
    class func readArrayWithCustomObjFromUserDefault(key: String) -> [[String: AnyObject]]? {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let data = defaults.objectForKey(key) as? NSData {
            if let dataArray = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [[String: AnyObject]] {
                return dataArray
            }
        }
        return nil
    }
    
    class func saveToUserDefault(key: String, value: AnyObject) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(value, forKey: key)
        defaults.synchronize()
    }
    
    class func retrieveFromUserDefault(key: String) -> AnyObject? {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.objectForKey(key)
    }
}
