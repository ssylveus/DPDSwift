//
//  DPDCredenntials.swift
//  DPDSwift
//
//  Created by Steeven Sylveus (Contractor) on 10/16/16.
//  Copyright © 2016 Steeven Sylveus. All rights reserved.
//

import UIKit

public class DPDCredenntials: NSObject {

    var accessToken: String?
    var installationId: String?
    var sessionId: String?
    
    static let sharedCredentials = DPDCredenntials.loadSaved()
    
    override init() {
    }
    
    required public init(coder aDecoder: NSCoder) {
        accessToken  = aDecoder.decodeObjectForKey("accessToken") as? String
        installationId  = aDecoder.decodeObjectForKey("installationId") as? String
        sessionId  = aDecoder.decodeObjectForKey("sessionId") as? String
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        if let accessToken = self.accessToken{
            aCoder.encodeObject(accessToken, forKey: "accessToken")
        }
        
        if let instId = installationId {
            aCoder.encodeObject(instId, forKey: "installationId")
        }
        
        if let sessionId = self.sessionId{
            aCoder.encodeObject(sessionId, forKey: "sessionId")
        }
    }
    
    public func save() {
        let data = NSKeyedArchiver.archivedDataWithRootObject(self)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "AppCredentials")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    public func clear() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey("AppCredentials")
    }
    
    public class func loadSaved() -> DPDCredenntials {
        if let data = NSUserDefaults.standardUserDefaults().objectForKey("AppCredentials") as? NSData {
            if let credentials = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? DPDCredenntials {
                return credentials
            }
        }
        
        return DPDCredenntials()
    }
    
    public class func generateDeviceId() {
        let uuid = NSUUID().UUIDString
        DPDCredenntials.sharedCredentials.installationId = uuid
        
        DPDCredenntials.sharedCredentials.save()
    }

}
