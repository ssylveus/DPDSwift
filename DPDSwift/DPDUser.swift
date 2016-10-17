//
//  DPDUser.swift
//  DPDSwift
//
//  Created by Steeven Sylveus (Contractor) on 10/16/16.
//  Copyright © 2016 Steeven Sylveus. All rights reserved.
//

import UIKit
import ObjectMapper

public class DPDUser: DPDObject {

    static let SharedUser = DPDUser()
    var username: String?
    var email: String?
    let currentUserUserDefaultKey = "CurrentUser"
    let usersEndpoint = "users"
    let sessionEndpoint = "session"
    let accessTokenEndpoint = "accesstoken"
    
    private var password: String?

    required public init() {
        super.init()
    }
    
    public class func currentUser<T: DPDUser>(mapper: T) -> T? {
        if let userArray = DPDHelper.readArrayWithCustomObjFromUserDefault(SharedUser.currentUserUserDefaultKey) {
            let users = DPDUser.convertToObj(Mapper<T>(), jsonArray: userArray)
            return users[0]
        }
        
        return nil
    }
    
    public class func convertToObj<T: DPDUser>(mapper: Mapper<T>, jsonArray: [[String: AnyObject]]) -> [T] {
        return Mapper<T>().mapArray(jsonArray)!
    }
    
    required public init?(_ map: Map) {
        super.init(map)
    }
    
    override public func mapping(map: Map) {
        super.mapping(map)
        
        username <- map["username"]
        password <- map["password"]
        email <- map["email"]
    }
    
    public class func userRequestObjt(username: String, password: String) -> [String: AnyObject] {
        var jsonObject = [String: AnyObject]()
        jsonObject.updateValue(username, forKey: "username")
        jsonObject.updateValue(password, forKey: "password")
        
        return jsonObject
    }
    
    public class func saveUserObjToDefaults<T: DPDUser>(user: T) {
        let userDict = Mapper<T>().toJSON(user)
        DPDHelper.writeArrayWithCustomObjToUserDefaults(SharedUser.currentUserUserDefaultKey, array: [userDict])
    }
    
    public class func createUser<T: DPDUser>(mapper: T, rootUrl: String, username: String, password: String, compBlock: CompletionBlock) {
        let jsonString = DPDHelper.toJsonString(userRequestObjt(username, password: password))
        
        DPDRequest.requestWithURL(rootUrl, endPointURL: SharedUser.usersEndpoint, parameters: nil, method: HTTPMethod.POST, jsonString: jsonString) { (response, responseHeader, error) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        let users = DPDObject.convertToDPDObject(mapper, response: [responseDict])
                        self.saveUserObjToDefaults(users[0])
                        self.login(rootUrl, username: username, password: password, compBlock: nil)
                        compBlock(response: users, responseHeader: responseHeader, error: nil)
                    }
                } else {
                    compBlock(response: response, responseHeader: responseHeader, error: error)
                }
            })
        }
    }
    
    public class func login(rootUrl: String, username: String, password: String, compBlock: CompletionBlock?) {
        let jsonString = DPDHelper.toJsonString(userRequestObjt(username, password: password))
        
        var sessionDict = [String: AnyObject]()
        sessionDict["installationId"] = DPDCredenntials.sharedCredentials.installationId
        
        DPDRequest.requestWithURL(rootUrl, endPointURL: SharedUser.usersEndpoint + "/login", parameters: nil, method: HTTPMethod.POST, jsonString: jsonString, requestHeader : sessionDict) { (response, responseHeader, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        if let sessionToken = responseDict["id"] as? String {
                            DPDHelper.saveToUserDefault(sessionTokenKey, value: sessionToken)
                            self.getAccessToken(rootUrl, compBlock: { (response, responseHeader, error) in
                                if let completionBlock = compBlock {
                                    completionBlock(response: responseDict, responseHeader: responseHeader, error: nil)
                                }
                            })
                        } else {
                            if let completionBlock = compBlock {
                                completionBlock(response: response, responseHeader: responseHeader, error: NSError(domain: "Unknown Error", code: 400, userInfo: nil))
                            }
                        }
                    }
                    
                } else {
                    if let completionBlock = compBlock {
                        completionBlock(response: response, responseHeader: responseHeader, error: error)
                    }
                }
                
            })
        }
    }
    
    public class func updateUser<T: DPDUser>(mapper: T, rootUrl: String, user: DPDUser, compBlock: CompletionBlock) {
        DPDRequest.requestWithURL(rootUrl, endPointURL: SharedUser.usersEndpoint + "/\(user.objectId!)", parameters: nil, method: HTTPMethod.PUT, jsonString: user.toJsonString()) { (response, responseHeader, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        let users = DPDObject.convertToDPDObject(mapper, response: [responseDict])
                        self.saveUserObjToDefaults(users[0])
                        compBlock(response: users, responseHeader: responseHeader, error: nil)
                    }
                } else {
                    compBlock(response: [], responseHeader: responseHeader, error: error)
                }
            })
        }
    }
    
    public class func getUser<T: DPDUser>(mapper: T, rootUrl: String, userId: String, compBlock: CompletionBlock) {
        DPDRequest.requestWithURL(rootUrl, endPointURL: SharedUser.usersEndpoint + "/\(userId)", parameters: nil, method: HTTPMethod.GET, jsonString: nil) { (response, responseHeader, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        let mnUsers = DPDObject.convertToDPDObject(mapper, response: [responseDict])
                        compBlock(response: mnUsers, responseHeader: responseHeader, error: nil)
                    }
                } else {
                    compBlock(response: response, responseHeader: responseHeader, error: error)
                }
            })
        }
    }
    
    public class func refreshCurrentUser<T: DPDUser>(mapper: T, rootUrl: String, token: String, compBlock: CompletionBlock) {
        var sessionDict = [String: AnyObject]()
        sessionDict["Cookie"] = "sid=\(token)"
        
        DPDRequest.requestWithURL(rootUrl, endPointURL: SharedUser.usersEndpoint + "/me", parameters: nil, method: HTTPMethod.GET, jsonString: nil, requestHeader: sessionDict) { (response, responseHeader, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        let users = DPDObject.convertToDPDObject(mapper, response: [responseDict])
                        self.saveUserObjToDefaults(users[0])
                        compBlock(response: users, responseHeader: responseHeader, error: nil)
                    }
                } else {
                    NSUserDefaults.standardUserDefaults().removeObjectForKey(SharedUser.currentUserUserDefaultKey)
                }
                
                compBlock(response: response, responseHeader: responseHeader, error: error)
            })
        }
    }
    
    public class func logOut(rootUrl: String) {
        if let token = DPDHelper.retrieveFromUserDefault(sessionTokenKey) as? String {
            var sessionDict = [String: AnyObject]()
            sessionDict["sessionToken"] = "sid=\(token)"
            
            guard let sessionId = DPDCredenntials.sharedCredentials.sessionId , sessionId.characters.count > 0  else {
                return
            }
            
            DPDRequest.requestWithURL(rootUrl, endPointURL: SharedUser.sessionEndpoint + "/\(sessionId)", parameters: sessionDict, method: HTTPMethod.DELETE, jsonString: nil) { (response, responseHeader, error) in
                
                if error == nil {
                    print("Session Removed Successfuly");
                } else {
                    print("Failed to remove sesion");
                }
            }
        }
        
        DPDCredenntials.sharedCredentials.clear()
    }
    
    public class func getAccessToken(rootUrl: String, compBlock: CompletionBlock) {
        DPDRequest.requestWithURL(rootUrl, endPointURL: SharedUser.accessTokenEndpoint, parameters: nil, method: HTTPMethod.GET, jsonString: nil) { (response, responseHeader, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        let userDict = responseDict["user"] as? [String: AnyObject];
                        let users = DPDObject.convertToDPDObject(DPDUser(), response: [userDict!])
                        self.saveUserObjToDefaults(users[0])
                        
                        if let accessToken = responseDict["accessToken"] as? String {
                            DPDCredenntials.sharedCredentials.accessToken = accessToken
                        }
                        
                        if let sessionId = responseDict["sessionId"] as? String {
                            DPDCredenntials.sharedCredentials.sessionId = sessionId
                        }
                        
                        DPDCredenntials.sharedCredentials.save()
                        
                        compBlock(response: users, responseHeader: responseHeader, error: nil)
                    }
                } else {
                    compBlock(response: response, responseHeader: responseHeader, error: error)
                }
            })
        }
    }
}
