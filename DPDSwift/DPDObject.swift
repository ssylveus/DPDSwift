//
//  DPDObject.swift
//  DPDSwift
//
//  Created by Steeven Sylveus (Contractor) on 10/15/16.
//  Copyright © 2016 Steeven Sylveus. All rights reserved.
//

import UIKit
import ObjectMapper

public class DPDObject: Mappable {

    var objectId: String?
    var createdAt: NSNumber?
    var updatedAt: NSNumber?
    
    required public init() {
        
    }
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        objectId <- map["id"]
        createdAt <- map["createdAt"]
        updatedAt <- map["updatedAt"]
    }
    
    public func toJson() -> [String: AnyObject]? {
        return Mapper<DPDObject>().toJSON(self)
    }
    
    public func toJsonString() -> String? {
        return DPDHelper.toJsonString(Mapper<DPDObject>().toJSON(self))
    }
    
    public class func convertToDPDObject<T: DPDObject>(mapper: T, response: [[String: AnyObject]]) -> [T] {
        if let responseArray = Mapper<T>().mapArray(response) {
            return responseArray
        }
        
        return []
    }
    
    //MARK: - CRUD OPERATIONS   
    
    public func createObject<T: DPDObject>(mapper: T, rootUrl: String, endPoint: String, compblock: CompletionBlock) {
        let jsonString = toJsonString()
        
        DPDRequest.requestWithURL(rootUrl, endPointURL: endPoint, parameters: nil, method: HTTPMethod.POST, jsonString: jsonString) { (response, responseHeader, error) -> Void in
            print(response)
            dispatch_async(dispatch_get_main_queue(), {
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        let mnObjects = DPDObject.convertToDPDObject(mapper, response: [responseDict])
                        compblock(response: mnObjects, responseHeader: responseHeader, error: nil)
                    }
                } else {
                    compblock(response: [], responseHeader: responseHeader, error: error)
                }
            })
            
        }
    }
    
    public func updateObjectInBackground<T: DPDObject>(mapper: T, rootUrl: String, endPoint: String, compblock: CompletionBlock) {
        let jsonString = toJsonString()
        
        DPDRequest.requestWithURL(rootUrl, endPointURL: endPoint + "/\(self.objectId!)", parameters: nil, method: HTTPMethod.PUT, jsonString: jsonString) { (response, responseHeader, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), {
                if error == nil {
                    if let responseDict = response as? [String: AnyObject] {
                        let mnObjects = DPDObject.convertToDPDObject(mapper, response: [responseDict])
                        compblock(response: mnObjects, responseHeader: responseHeader, error: nil)
                    }
                } else {
                    compblock(response: [], responseHeader: responseHeader, error: error)
                }
                
            })
        }
    }
    
    public func deleteObjectInBackground(rootUrl: String, endPoint: String, objectId: String, param: [String: AnyObject]? = nil, compblock: CompletionBlock) {
        let jsonString = toJsonString()
        
        DPDRequest.requestWithURL(rootUrl, endPointURL: endPoint + "/\(objectId)", parameters: param, method: HTTPMethod.DELETE, jsonString: jsonString) { (response, responseHeader, error) -> Void in
            
            if error == nil {
                print(response)
                compblock(response: [["message": "Object deleted successfully"]], responseHeader: responseHeader, error: nil)
            } else {
                compblock(response: [], responseHeader: responseHeader, error: error)
            }
        }
        
    }


}
