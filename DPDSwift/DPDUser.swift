//
//  DPDUser.swift
//  DPDSwift
//
//  Created by Steeven Sylveus (Contractor) on 10/16/16.
//  Copyright © 2016 Steeven Sylveus. All rights reserved.
//

import UIKit

open class DPDUser: DPDObject {
    
    static let SharedUser = DPDUser()
    
    public var username: String?
    public var password: String?
    
    let currentUserUserDefaultKey = "CurrentUser"
    let usersEndpoint = "users"
    let sessionEndpoint = "session"
    let accessTokenEndpoint = "accesstoken"
    
    private enum CodingKeys: String, CodingKey {
        case username
        case password
    }
    
    override init() {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.username = try? container.decode(String.self, forKey: .username)
        self.password = try? container.decode(String.self, forKey: .password)
        try super.init(from: decoder)
    }
    
    override open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(username, forKey: .username)
        try? super.encode(to: encoder)
    }
    
    open class func currentUser<T: DPDUser>(_ mapper: T.Type) -> T? {
        if let userArray = DPDHelper.readArrayWithCustomObjFromUserDefault(SharedUser.currentUserUserDefaultKey) {
            
            guard let data = try? JSONSerialization.data(withJSONObject: userArray, options: []) else {
                return nil
            }
            
            do {
                let users = try [T].decode(data: data)
                return users[0]
            } catch {
                return nil
            }
        }
        
        return nil
    }
    
    open class func convertToObj<T: DPDUser>(_ mapper: T.Type, jsonArray: [[String: Any]]) -> [T] {
        
        guard let data = try? JSONSerialization.data(withJSONObject: jsonArray, options: []) else {
            return []
        }
        
        do {
            return try [T].decode(data: data)
        } catch {
            return []
        }
    }
    
    open class func userRequestObjt(_ username: String, password: String) -> [String: AnyObject] {
        var jsonObject = [String: AnyObject]()
        jsonObject.updateValue(username as AnyObject, forKey: "username")
        jsonObject.updateValue(password as AnyObject, forKey: "password")
        return jsonObject
    }
    
    open class func saveUserObjToDefaults<T: DPDUser>(_ user: T) {
        if let userDict = user.toJSON() as? [String: Any] {
            DPDHelper.writeArrayWithCustomObjToUserDefaults(SharedUser.currentUserUserDefaultKey, array: [userDict])
        }
        
    }
    
    open class func createUser<T: DPDUser>(_ mapper: T.Type, rootUrl: String, username: String, password: String, compBlock: @escaping CompletionBlock) {
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
    
    open class func login<T: DPDUser>(_ mapper: T.Type, rootUrl: String, username: String, password: String, compBlock: CompletionBlock?) {
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
    
    open class func updateUser<T: DPDUser>(_ mapper: T.Type, rootUrl: String, user: DPDUser, compBlock: @escaping CompletionBlock) {
        DPDRequest.requestWithURL(rootUrl, endPointURL: SharedUser.usersEndpoint + "/\(user.objectId!)", parameters: nil, method: HTTPMethod.PUT, jsonString: user.toJSONString()) { (response, responseHeader, error) -> Void in
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
    
    open class func getUser<T: DPDUser>(_ mapper: T.Type, rootUrl: String, userId: String, compBlock: @escaping CompletionBlock) {
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
    
    open class func refreshCurrentUser<T: DPDUser>(_ mapper: T.Type, rootUrl: String, token: String, compBlock: @escaping CompletionBlock) {
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
        DPDHelper.removeFromUserDefault(SharedUser.currentUserUserDefaultKey)
        if let token = DPDHelper.retrieveFromUserDefault(sessionTokenKey) as? String {
            var sessionDict = [String: AnyObject]()
            sessionDict["sessionToken"] = "sid=\(token)" as AnyObject?
            
            guard let sessionId = DPDCredentials.sharedCredentials.sessionId , sessionId.count > 0  else {
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
    
    open class func getAccessToken<T: DPDUser>(_ mapper: T.Type, rootUrl: String, compBlock: @escaping CompletionBlock) {
        DPDRequest.requestWithURL(rootUrl, endPointURL: SharedUser.accessTokenEndpoint, parameters: nil, method: HTTPMethod.GET, jsonString: nil) { (response, responseHeader, error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        let userDict = responseDict["user"] as? [String: AnyObject];
                        let users = DPDObject.convertToDPDObject(mapper, response: [userDict!])
                        if users.count > 0 {
                            self.saveUserObjToDefaults(users[0])
                        }
                        
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

