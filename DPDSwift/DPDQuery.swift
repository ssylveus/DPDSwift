//
//  DPDQuery.swift
//  DPDSwift
//
//  Created by Steeven Sylveus (Contractor) on 10/16/16.
//  Copyright © 2016 Steeven Sylveus. All rights reserved.
//

import UIKit
import ObjectMapper

public class DPDQuery: NSObject {

    typealias QueryCompletionBlock = (response: [AnyObject], error: NSError?) -> Void

    enum QueryCondition: Int {
        case GreaterThan = 0
        case GreaterThanEqualTo = 1
        case LessThan = 2
        case LessThanEqual = 3
        case NotEqual = 4
        case Equal = 5
        case Contains = 6
        case Regex = 7
        case None = 8
    }
    
    enum OrderType: Int {
        case Ascending = 1
        case Descending = -1
    }
    
    var queryCondition: QueryCondition = .None
    var sortingOrder: OrderType = .Ascending
    var limit: Int? = nil
    var skip: Int? = nil
    var queryField: String?
    var queryFieldValue: NSObject?
    var sortField: String?
    private var queryParam: [String: AnyObject]? = nil
    private var callingThread: NSThread? = nil
    
    class func findObject(rootUrl: String, objectId: String, endPoint: String, responseDataModel: DPDObject, compblock: QueryCompletionBlock) {
        let query = DPDQuery()
        query.makeApiRequest(rootUrl, endpointValue: endPoint + "/\(objectId)", compblock: compblock)
    }
    
    override init() {
        queryCondition = .None
        sortingOrder = .Ascending
        limit = nil
        skip = nil
        queryField = nil
        queryFieldValue = nil
        sortField = nil
    }
    
    init(queryCondition: QueryCondition?,
         ordertype: OrderType,
         limit: Int?,
         skip: Int?,
         queryField: String?,
         queryFieldValue: NSObject?,
         sortField: String?) {
        self.queryCondition = queryCondition!
        self.sortingOrder = ordertype
        self.limit = limit
        self.skip = skip
        self.queryField = queryField
        self.queryFieldValue = queryFieldValue
        self.sortField = sortField
    }
    
    func findObject(rootUrl: String, endPoint: String, compblock: QueryCompletionBlock) {
        processQueryInfo()
        makeApiRequest(rootUrl, endpointValue: endPoint, compblock: compblock)
    }
    
    func findMappableObject<T: DPDObject>(mapper: Mapper<T>, rootUrl: String, endPoint: String, compblock: QueryCompletionBlock) {
        processQueryInfo()
        makeApiRequestForMappableObject(mapper, rootUrl: rootUrl, endpointValue: endPoint, compblock: compblock)
    }
    
    private func makeApiRequestForMappableObject<T: DPDObject>(mapper: Mapper<T>, rootUrl: String, endpointValue: String, compblock: QueryCompletionBlock) {
        
        executeRequest(rootUrl, endpointValue: endpointValue) { (response, responseHeader, error) in
            if error == nil {
                var mnObjects = [T]()
                if let responseDict = response as? [String: AnyObject] {
                    mnObjects = DPDObject.convertToDPDObject(mapper, response: [responseDict])
                    
                } else {
                    mnObjects = DPDObject.convertToDPDObject(Mapper<T>(), response: response as! [[String: AnyObject]])
                }
                
                compblock(response: mnObjects, error: nil)
            } else {
                compblock(response: [], error: error)
            }
            
        }
    }
    
    private func makeApiRequest(rootUrl: String, endpointValue: String, compblock: QueryCompletionBlock) {
        executeRequest(rootUrl, endpointValue: endpointValue) { (response, responseHeader, error) in
            if error == nil {
                if let responseDict = response as? [String: AnyObject] {
                    compblock(response: [responseDict], error: nil)
                } else {
                    compblock(response: [response!], error: nil)
                }
            } else {
                compblock(response: [], error: error)
            }
        }
    }
    
    private func executeRequest(rootUrl: String,  endpointValue: String, compblock: CompletionBlock) {
        DPDRequest.requestWithURL(rootUrl, endPointURL: endpointValue, parameters: queryParam, method: HTTPMethod.GET, jsonString: nil) { (response, responseHeader, error) in
            
            dispatch_async(dispatch_get_main_queue(), {
                compblock(response: response, responseHeader: responseHeader, error: error)
            })
        }
    }
    
    func processQueryInfo() {
        queryParam = [String: AnyObject]()
        
        if queryField != nil && queryCondition != .None {
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
    private func processQuerycondition() {
        switch queryCondition {
        case .GreaterThan:
            queryParam?.addDictionary(dictionary: processingGreaterThan())
        case .GreaterThanEqualTo:
            queryParam?.addDictionary(dictionary: processingGreaterThanEqualTo())
        case .LessThan:
            queryParam?.addDictionary(dictionary: processingLessThan())
        case .LessThanEqual:
            queryParam?.addDictionary(dictionary: processingLessThanEqualTo())
        case .NotEqual:
            queryParam?.addDictionary(dictionary: processingNotEqualTo())
        case .Contains:
            queryParam?.addDictionary(dictionary: processingContainIn())
        case .Regex:
            queryParam?.addDictionary(dictionary: processingRegex())
        default:
            queryParam?.addDictionary(dictionary: processingEqualTo())
        }
    }
    
    private func processingGreaterThan() -> [String: NSObject] {
        var queryParam = [String: NSObject]()
        var valueDict = [String: NSObject]()
        valueDict["$gt"] = queryFieldValue
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    private func processingGreaterThanEqualTo() -> [String: NSObject] {
        var queryParam = [String: NSObject]()
        var valueDict = [String: NSObject]()
        valueDict["$gte"] = queryFieldValue
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    private func processingLessThan() -> [String: NSObject] {
        var queryParam = [String: NSObject]()
        var valueDict = [String: NSObject]()
        valueDict["$lt"] = queryFieldValue
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    private func processingLessThanEqualTo() -> [String: NSObject] {
        var queryParam = [String: NSObject]()
        var valueDict = [String: NSObject]()
        valueDict["$lte"] = queryFieldValue
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    private func processingNotEqualTo() -> [String: NSObject] {
        var queryParam = [String: NSObject]()
        var valueDict = [String: NSObject]()
        valueDict["$ne"] = queryFieldValue
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    private func processingEqualTo() -> [String: NSObject] {
        var queryParam = [String: NSObject]()
        var valueDict = [String: NSObject]()
        valueDict["$eq"] = queryFieldValue
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    private func processingContainIn() -> [String: NSObject] {
        var queryParam = [String: NSObject]()
        var valueDict = [String: NSObject]()
        valueDict["$in"] = queryFieldValue
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    private func processingRegex() -> [String: NSObject] {
        var queryParam = [String: NSObject]()
        var valueDict = [String: NSObject]()
        valueDict["$regex"] = queryFieldValue
        valueDict["$options"] = "i"
        queryParam[queryField!] = valueDict
        return queryParam
    }
    
    private func processingSortingOrder() -> [String: NSObject] {
        var sortingParm = [String: NSObject]()
        var sortindDict = [String: NSObject]()
        sortindDict.updateValue(NSNumber(integer: sortingOrder.rawValue), forKey: sortField!)
        //sortindDict[sortField!] = NSNumber(integer: sortingOrder.rawValue)
        sortingParm["$sort"] = sortindDict
        return sortingParm
    }
    
    private func processingLimit() -> [String: NSObject] {
        var limitParm = [String: NSObject]()
        limitParm["$limit"] = NSNumber(integer: limit!)
        
        return limitParm
    }
    
    private func processingSkip() -> [String: NSObject] {
        var skipParm = [String: NSObject]()
        skipParm["$skip"] = NSNumber(integer: skip!)
        return skipParm
    }

}

extension Dictionary {
    
    mutating func addDictionary(dictionary dictionary:Dictionary) {
        for (key,value) in dictionary {
            self.updateValue(value, forKey:key)
        }
    }
}
