//
//  DPDHelper.swift
//  DPDSwift
//
//Created by Sylveus, Steeven on 11/8/18.
//

import UIKit
import KeychainSwift

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
    
    open class func getSessionId() -> String? {
        if let token = DPDKeyChain.getString(sessionTokenKey) {
            return "sid=\(token)"
        }
        return nil
    }
    
    open class func getAccessToken() -> String {
        if let token = DPDCredentials.sharedCredentials.accessToken {
            return token
        }
        
        return ""
    }
}
