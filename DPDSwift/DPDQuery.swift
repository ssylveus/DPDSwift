//
//  DPDQuery.swift
//  DPDSwift
//
//  Created by Steeven Sylveus (Contractor) on 10/16/16.
//  Copyright © 2016 Steeven Sylveus. All rights reserved.
//

import UIKit
import ObjectMapper

open class DPDQuery: NSObject {

    public typealias QueryCompletionBlock = (_ response: [Any], _ error: Error?) -> Void

    public enum QueryCondition: Int {
        case greaterThan = 0
        case greaterThanEqualTo = 1
        case lessThan = 2
        case lessThanEqual = 3
        case notEqual = 4
        case equal = 5
        case contains = 6
        case regex = 7
        case none = 8
    }
    
    public enum OrderType: Int {
        case ascending = 1
        case descending = -1
    }
    
    var queryCondition: QueryCondition = .none
    var sortingOrder: OrderType = .ascending
    var limit: Int? = nil
    var skip: Int? = nil
    var queryField: String?
    var queryFieldValue: Any?
    var sortField: String?
    fileprivate var queryParam: [String: Any]? = nil
    fileprivate var callingThread: Thread? = nil
    
    open class func findObject(_ rootUrl: String, objectId: String, endPoint: String, responseDataModel: DPDObject, compblock: @escaping QueryCompletionBlock) {
        let query = DPDQuery()
        query.makeApiRequest(rootUrl, endpointValue: endPoint + "/\(objectId)", compblock: compblock)
    }
    
    public override init() {
        queryCondition = .none
        sortingOrder = .ascending
        limit = nil
        skip = nil
        queryField = nil
        queryFieldValue = nil
        sortField = nil
    }
    
    public init(queryCondition: QueryCondition = .none,
         ordertype: OrderType,
         limit: Int?,
         skip: Int?,
         queryField: String?,
         queryFieldValue: Any?,
         sortField: String?) {
        self.queryCondition = queryCondition
        self.sortingOrder = ordertype
        self.limit = limit
        self.skip = skip
        self.queryField = queryField
        self.queryFieldValue = queryFieldValue
        self.sortField = sortField
    }
    
    open func findObject(_ rootUrl: String, endPoint: String, compblock: @escaping QueryCompletionBlock) {
        processQueryInfo()
        makeApiRequest(rootUrl, endpointValue: endPoint, compblock: compblock)
    }
    
    open func findMappableObject<T: DPDObject>(_ mapper: T.Type, rootUrl: String, endPoint: String, compblock: @escaping QueryCompletionBlock) {
        processQueryInfo()
        makeApiRequestForMappableObject(mapper, rootUrl: rootUrl, endpointValue: endPoint, compblock: compblock)
    }
    
    fileprivate func makeApiRequestForMappableObject<T: DPDObject>(_ mapper: T.Type, rootUrl: String, endpointValue: String, compblock: @escaping QueryCompletionBlock) {
        
        executeRequest(rootUrl, endpointValue: endpointValue) { (response, responseHeader, error) in
            if error == nil {
                var mnObjects = [T]()
                if let responseDict = response as? [String: Any] {
                    mnObjects = DPDObject.convertToDPDObject(mapper, response: [responseDict])
                    
                } else {
                    mnObjects = DPDObject.convertToDPDObject(mapper, response: response as! [[String: Any]])
                }
                
                compblock(mnObjects, nil)
            } else {
                compblock([], error as NSError?)
            }
            
        }
    }
    
    fileprivate func makeApiRequest(_ rootUrl: String, endpointValue: String, compblock: @escaping QueryCompletionBlock) {
        executeRequest(rootUrl, endpointValue: endpointValue) { (response, responseHeader, error) in
            if error == nil {
                if let responseDict = response as? [String: Any] {
                    compblock([responseDict as Any], nil)
                } else {
                    compblock([response!], nil)
                }
            } else {
                compblock([], error)
            }
        }
    }
    
    fileprivate func executeRequest(_ rootUrl: String,  endpointValue: String, compblock: @escaping CompletionBlock) {
        DPDRequest.requestWithURL(rootUrl, endPointURL: endpointValue, parameters: queryParam, method: HTTPMethod.GET, jsonString: nil) { (response, responseHeader, error) in
            
            DispatchQueue.main.async(execute: {
                compblock(response, responseHeader, error)
            })
        }
    }
    
    func processQueryInfo() {
        queryParam = [String: Any]()
        
        if queryField != nil && queryCondition != .none {
            processQuerycondition()
        }
        
        if let _ = sortField {
            queryParam?.addDictionary(dictionary: processingSortingOrder())
        }
        
        if let _ = limit {
            queryParam?.addDictionary(dictionary: processingLimit())
        }
        
        if let _ = skip {
            queryParam?.addDictionary(dictionary: processingSkip())
        }
        
    }
    
}

extension DPDQuery {
    //Mark - Querycondition Methods
    fileprivate func processQuerycondition() {
        switch queryCondition {
        case .greaterThan:
            queryParam?.addDictionary(dictionary: processingGreaterThan())
        case .greaterThanEqualTo:
            queryParam?.addDictionary(dictionary: processingGreaterThanEqualTo())
        case .lessThan:
            queryParam?.addDictionary(dictionary: processingLessThan())
        case .lessThanEqual:
            queryParam?.addDictionary(dictionary: processingLessThanEqualTo())
        case .notEqual:
            queryParam?.addDictionary(dictionary: processingNotEqualTo())
        case .contains:
            queryParam?.addDictionary(dictionary: processingContainIn())
        case .regex:
            queryParam?.addDictionary(dictionary: processingRegex())
        default:
            queryParam?.addDictionary(dictionary: processingEqualTo())
        }
    }
    
    fileprivate func processingGreaterThan() -> [String: Any] {
        var queryParam = [String: Any]()
        var valueDict = [String: Any]()
        valueDict["$gt"] = queryFieldValue
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    fileprivate func processingGreaterThanEqualTo() -> [String: Any] {
        var queryParam = [String: Any]()
        var valueDict = [String: Any]()
        valueDict["$gte"] = queryFieldValue
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    fileprivate func processingLessThan() -> [String: Any] {
        var queryParam = [String: Any]()
        var valueDict = [String: Any]()
        valueDict["$lt"] = queryFieldValue
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    fileprivate func processingLessThanEqualTo() -> [String: Any] {
        var queryParam = [String: Any]()
        var valueDict = [String: Any]()
        valueDict["$lte"] = queryFieldValue
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    fileprivate func processingNotEqualTo() -> [String: Any] {
        var queryParam = [String: Any]()
        var valueDict = [String: Any]()
        valueDict["$ne"] = queryFieldValue
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    fileprivate func processingEqualTo() -> [String: Any] {
        var queryParam = [String: Any]()
        var valueDict = [String: Any]()
        valueDict["$eq"] = queryFieldValue
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    fileprivate func processingContainIn() -> [String: Any] {
        var queryParam = [String: Any]()
        var valueDict = [String: Any]()
        valueDict["$in"] = queryFieldValue
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    fileprivate func processingRegex() -> [String: Any] {
        var queryParam = [String: Any]()
        var valueDict = [String: Any]()
        valueDict["$regex"] = queryFieldValue
        valueDict["$options"] = "i"
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    fileprivate func processingSortingOrder() -> [String: Any] {
        var sortingParm = [String: Any]()
        var sortindDict = [String: Any]()
        sortindDict.updateValue(NSNumber(value: sortingOrder.rawValue as Int), forKey: sortField!)
        //sortindDict[sortField!] = NSNumber(integer: sortingOrder.rawValue)
        sortingParm["$sort"] = sortindDict
        return sortingParm
    }
    
    fileprivate func processingLimit() -> [String: Any] {
        var limitParm = [String: Any]()
        limitParm["$limit"] = NSNumber(value: limit! as Int)
        
        return limitParm
    }
    
    fileprivate func processingSkip() -> [String: Any] {
        var skipParm = [String: Any]()
        skipParm["$skip"] = NSNumber(value: skip! as Int)
        return skipParm
    }

}

extension Dictionary {
    
    mutating func addDictionary(dictionary:Dictionary) {
        for (key,value) in dictionary {
            self.updateValue(value, forKey:key)
        }
    }
}
