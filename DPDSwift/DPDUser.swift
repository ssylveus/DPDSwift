//
//  DPDUser.swift
//  DPDSwift
//
//  Created by Steeven Sylveus (Contractor) on 10/16/16.
//  Copyright © 2016 Steeven Sylveus. All rights reserved.
//

import UIKit
import ObjectMapper

open class DPDUser: DPDObject {

    static let SharedUser = DPDUser()
    public var username: String?
    public var email: String?
    public let currentUserUserDefaultKey = "CurrentUser"
    public var password: String?
    
    let usersEndpoint = "users"
    let sessionEndpoint = "session"
    let accessTokenEndpoint = "accesstoken"

    required public init() {
        super.init()
    }
    
    open class func currentUser<T: DPDUser>(_ mapper: T) -> T? {
        if let userArray = DPDHelper.readArrayWithCustomObjFromUserDefault(SharedUser.currentUserUserDefaultKey) {
            let users = DPDUser.convertToObj(Mapper<T>(), jsonArray: userArray)
            return users[0]
        }
        
        return nil
    }
    
    open class func convertToObj<T: DPDUser>(_ mapper: Mapper<T>, jsonArray: [[String: Any]]) -> [T] {
        return Mapper<T>().mapArray(JSONArray: jsonArray)!
    }
    
    required public init?(map: Map) {
        super.init(map: map)
    }
    
    
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        username <- map["username"]
        password <- map["password"]
        email <- map["email"]
    }
    
    open class func userRequestObjt(_ username: String, password: String) -> [String: AnyObject] {
        var jsonObject = [String: AnyObject]()
        jsonObject.updateValue(username as AnyObject, forKey: "username")
        jsonObject.updateValue(password as AnyObject, forKey: "password")
        
        return jsonObject
    }
    
    open class func saveUserObjToDefaults<T: DPDUser>(_ user: T) {
        let userDict = Mapper<T>().toJSON(user)
        DPDHelper.writeArrayWithCustomObjToUserDefaults(SharedUser.currentUserUserDefaultKey, array: [userDict])
    }
    
    open class func createUser<T: DPDUser>(_ mapper: T, rootUrl: String, username: String, password: String, compBlock: @escaping CompletionBlock) {
        let jsonString = DPDHelper.toJsonString(userRequestObjt(username, password: password))
        
        DPDRequest.requestWithURL(rootUrl, endPointURL: SharedUser.usersEndpoint, parameters: nil, method: HTTPMethod.POST, jsonString: jsonString) { (response, responseHeader, error) -> Void in
            
            DispatchQueue.main.async(execute: { () -> Void in
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        let users = DPDObject.convertToDPDObject(mapper, response: [responseDict])
                        self.saveUserObjToDefaults(users[0])
                        self.login(mapper, rootUrl: rootUrl, username: username, password: password, compBlock: nil)
                        compBlock(users, responseHeader, nil)
                    }
                } else {
                    compBlock(response, responseHeader, error)
                }
            })
        }
    }
    
    open class func login<T: DPDUser>(_ mapper: T, rootUrl: String, username: String, password: String, compBlock: CompletionBlock?) {
        let jsonString = DPDHelper.toJsonString(userRequestObjt(username, password: password))
        
        var sessionDict = [String: AnyObject]()
        sessionDict["installationId"] = DPDCredentials.sharedCredentials.installationId as AnyObject?
        
        DPDRequest.requestWithURL(rootUrl, endPointURL: SharedUser.usersEndpoint + "/login", parameters: nil, method: HTTPMethod.POST, jsonString: jsonString, requestHeader : sessionDict) { (response, responseHeader, error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        if let sessionToken = responseDict["id"] as? String {
                            DPDHelper.saveToUserDefault(sessionTokenKey, value: sessionToken as AnyObject)
                            self.getAccessToken(mapper, rootUrl: rootUrl, compBlock: { (response, responseHeader, error) in
                                if let completionBlock = compBlock {
                                    completionBlock(response, responseHeader, nil)
                                }
                            })
                        } else {
                            if let completionBlock = compBlock {
                                completionBlock(response, responseHeader, NSError(domain: "Unknown Error", code: 400, userInfo: nil))
                            }
                        }
                    }
                    
                } else {
                    if let completionBlock = compBlock {
                        completionBlock(response, responseHeader, error)
                    }
                }
                
            })
        }
    }
    
    open class func updateUser<T: DPDUser>(_ mapper: T, rootUrl: String, user: DPDUser, compBlock: @escaping CompletionBlock) {
        DPDRequest.requestWithURL(rootUrl, endPointURL: SharedUser.usersEndpoint + "/\(user.objectId!)", parameters: nil, method: HTTPMethod.PUT, jsonString: user.toJsonString()) { (response, responseHeader, error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        let users = DPDObject.convertToDPDObject(mapper, response: [responseDict])
                        self.saveUserObjToDefaults(users[0])
                        compBlock(users, responseHeader, nil)
                    }
                } else {
                    compBlock([], responseHeader, error)
                }
            })
        }
    }
    
    open class func getUser<T: DPDUser>(_ mapper: T, rootUrl: String, userId: String, compBlock: @escaping CompletionBlock) {
        DPDRequest.requestWithURL(rootUrl, endPointURL: SharedUser.usersEndpoint + "/\(userId)", parameters: nil, method: HTTPMethod.GET, jsonString: nil) { (response, responseHeader, error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        let mnUsers = DPDObject.convertToDPDObject(mapper, response: [responseDict])
                        compBlock(mnUsers, responseHeader, nil)
                    }
                } else {
                    compBlock(response, responseHeader, error)
                }
            })
        }
    }
    
    open class func refreshCurrentUser<T: DPDUser>(_ mapper: T, rootUrl: String, token: String, compBlock: @escaping CompletionBlock) {
        var sessionDict = [String: AnyObject]()
        sessionDict["Cookie"] = "sid=\(token)" as AnyObject?
        
        DPDRequest.requestWithURL(rootUrl, endPointURL: SharedUser.usersEndpoint + "/me", parameters: nil, method: HTTPMethod.GET, jsonString: nil, requestHeader: sessionDict) { (response, responseHeader, error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        let users = DPDObject.convertToDPDObject(mapper, response: [responseDict])
                        self.saveUserObjToDefaults(users[0])
                        compBlock(users, responseHeader, nil)
                    }
                } else {
                    UserDefaults.standard.removeObject(forKey: SharedUser.currentUserUserDefaultKey)
                }
                
                compBlock(response, responseHeader, error)
            })
        }
    }
    
    open class func logOut(_ rootUrl: String) {
        if let token = DPDHelper.retrieveFromUserDefault(sessionTokenKey) as? String {
            var sessionDict = [String: AnyObject]()
            sessionDict["sessionToken"] = "sid=\(token)" as AnyObject?
            
            guard let sessionId = DPDCredentials.sharedCredentials.sessionId , sessionId.characters.count > 0  else {
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
        
        DPDCredentials.sharedCredentials.clear()
    }
    
    open class func getAccessToken<T: DPDUser>(_ mapper: T, rootUrl: String, compBlock: @escaping CompletionBlock) {
        DPDRequest.requestWithURL(rootUrl, endPointURL: SharedUser.accessTokenEndpoint, parameters: nil, method: HTTPMethod.GET, jsonString: nil) { (response, responseHeader, error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        let userDict = responseDict["user"] as? [String: AnyObject];
                        let users = DPDObject.convertToDPDObject(mapper, response: [userDict!])
                        self.saveUserObjToDefaults(users[0])
                        
                        if let accessToken = responseDict["accessToken"] as? String {
                            DPDCredentials.sharedCredentials.accessToken = accessToken
                        }
                        
                        if let sessionId = responseDict["sessionId"] as? String {
                            DPDCredentials.sharedCredentials.sessionId = sessionId
                        }
                        
                        DPDCredentials.sharedCredentials.save()
                        
                        compBlock(users, responseHeader, nil)
                    }
                } else {
                    compBlock(response, responseHeader, error)
                }
            })
        }
    }
}
