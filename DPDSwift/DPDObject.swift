//
//  DPDObject.swift
//  DPDSwift
//
//  Created by Steeven Sylveus (Contractor) on 10/15/16.
//  Copyright © 2016 Steeven Sylveus. All rights reserved.
//

import UIKit
import ObjectMapper

open class DPDObject: Mappable {

    public var objectId: String?
    public var createdAt: TimeInterval?
    public var updatedAt: TimeInterval?
    
    required public init() {
        
    }
    
    required public init?(map: Map) {
        
    }
    
    open func mapping(map: Map) {
        objectId <- map["id"]
        createdAt <- map["createdAt"]
        updatedAt <- map["updatedAt"]
    }
    
    open func toJson() -> [String: Any]? {
        return Mapper<DPDObject>().toJSON(self)
    }
    
    open func toJsonString() -> String? {
        return DPDHelper.toJsonString(Mapper<DPDObject>().toJSON(self))
    }
    
    open class func convertToDPDObject<T: DPDObject>(_ mapper: T, response: [[String: Any]]) -> [T] {
        return Mapper<T>().mapArray(JSONArray: response)
    }
    
    //MARK: - CRUD OPERATIONS   
    
    open func createObject<T: DPDObject>(_ mapper: T, rootUrl: String, endPoint: String, compblock: @escaping CompletionBlock) {
        let jsonString = toJsonString()
        
        DPDRequest.requestWithURL(rootUrl, endPointURL: endPoint, parameters: nil, method: HTTPMethod.POST, jsonString: jsonString) { (response, responseHeader, error) -> Void in
            print(response ?? "")
            DispatchQueue.main.async(execute: {
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        let mnObjects = DPDObject.convertToDPDObject(mapper, response: [responseDict])
                        compblock(mnObjects, responseHeader, nil)
                    }
                } else {
                    compblock([], responseHeader, error)
                }
            })
            
        }
    }
    
    open func updateObject<T: DPDObject>(_ mapper: T, rootUrl: String, endPoint: String, compblock: @escaping CompletionBlock) {
        let jsonString = toJsonString()
        
        DPDRequest.requestWithURL(rootUrl, endPointURL: endPoint + "/\(self.objectId!)", parameters: nil, method: HTTPMethod.PUT, jsonString: jsonString) { (response, responseHeader, error) -> Void in
            DispatchQueue.main.async(execute: {
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        let mnObjects = DPDObject.convertToDPDObject(mapper, response: [responseDict])
                        compblock(mnObjects, responseHeader, nil)
                    }
                } else {
                    compblock([], responseHeader, error)
                }
                
            })
        }
    }
    
    open func deleteObject(_ rootUrl: String, endPoint: String, objectId: String, param: [String: AnyObject]? = nil, compblock: @escaping CompletionBlock) {
        let jsonString = toJsonString()
        
        DPDRequest.requestWithURL(rootUrl, endPointURL: endPoint + "/\(objectId)", parameters: param, method: HTTPMethod.DELETE, jsonString: jsonString) { (response, responseHeader, error) -> Void in
            
            if error == nil {
                print(response ?? "")
                compblock([["message": "Object deleted successfully"]], responseHeader, nil)
            } else {
                compblock([], responseHeader, error)
            }
        }
        
    }


}
