//
//  DPDCredenntials.swift
//  DPDSwift
//
//  Created by Steeven Sylveus (Contractor) on 10/16/16.
//  Copyright © 2016 Steeven Sylveus. All rights reserved.
//

import UIKit

open class DPDCredentials: NSObject {
    
    var accessToken: String?
    var installationId: String?
    var sessionId: String?
    
    static let sharedCredentials = DPDCredentials.loadSaved()
    
    override init() {
    }
    
    required public init(coder aDecoder: NSCoder) {
        accessToken  = aDecoder.decodeObject(forKey: "accessToken") as? String
        installationId  = aDecoder.decodeObject(forKey: "installationId") as? String
        sessionId  = aDecoder.decodeObject(forKey: "sessionId") as? String
    }
    
    func encodeWithCoder(_ aCoder: NSCoder) {
        if let accessToken = self.accessToken{
            aCoder.encode(accessToken, forKey: "accessToken")
        }
        
        if let instId = installationId {
            aCoder.encode(instId, forKey: "installationId")
        }
        
        if let sessionId = self.sessionId{
            aCoder.encode(sessionId, forKey: "sessionId")
        }
    }
    
    func save() {
        let data = NSKeyedArchiver.archivedData(withRootObject: self)
        UserDefaults.standard.set(data, forKey: "AppCredentials")
        UserDefaults.standard.synchronize()
    }
    
    func clear() {
        UserDefaults.standard.removeObject(forKey: "AppCredentials")
    }
    
    class func loadSaved() -> DPDCredentials {
        if let data = UserDefaults.standard.object(forKey: "AppCredentials") as? Data {
            if let credentials = NSKeyedUnarchiver.unarchiveObject(with: data) as? DPDCredentials {
                return credentials
            }
        }
        
        return DPDCredentials()
    }
    
    class func generateDeviceId() {
        let uuid = UUID().uuidString
        DPDCredentials.sharedCredentials.installationId = uuid
        
        DPDCredentials.sharedCredentials.save()
    }
    
}
