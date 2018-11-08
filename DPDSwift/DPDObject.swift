//
//  DPDObject.swift
//  DPDSwift
//
//  Created by Steeven Sylveus (Contractor) on 10/15/16.
//  Copyright © 2016 Steeven Sylveus. All rights reserved.
//

import UIKit

extension Decodable {
    static func decode(data: Data) throws -> Self {
        let decoder = JSONDecoder()
        return try decoder.decode(Self.self, from: data)
    }
}

public extension Encodable {
    func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(self)
    }
    
    func toJSON() -> Any? {
        if let data = try? JSONEncoder().encode(self) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            } catch {
                return nil
            }
        }
        return nil
    }
    
    func toJSONString() -> String? {
        do {
            let data =  try encode()
            return String(data: data, encoding: .utf8)
        } catch  {
            return nil
        }
    }
}

open class DPDObject: NSObject, Codable {

    open var objectId: String?
    open var createdAt: TimeInterval?
    open var updatedAt: TimeInterval?
    
    private enum CodingKeys: String, CodingKey {
        case objectId = "id"
        case createdAt
        case updatedAt
    }
    
    public override init() {
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.objectId = try? container.decode(String.self, forKey: .objectId)
        self.createdAt = try? container.decode(Double.self, forKey: .createdAt)
        self.updatedAt = try? container.decode(Double.self, forKey: .updatedAt)
    }
    
    open class func convertToDPDObject<T: DPDObject>(_ mapper: T.Type, response: [[String: Any]]) -> [T] {
        guard let data = try? JSONSerialization.data(withJSONObject: response, options: []) else {
            return []
        }
        
        do {
            
            return try [T].decode(data: data)
        } catch  {
            return []
        }
    }
    
    //MARK: - CRUD OPERATIONS   
    
    open func createObject<T:
        DPDObject>(_ mapper: T.Type, rootUrl: String? = nil, endPoint: String, compblock: @escaping CompletionBlock) {
        
        guard let baseUrl = rootUrl ?? DPDConstants.rootUrl else {
            compblock(nil, nil, NSError(domain: "Invalid is required", code: -1, userInfo: nil))
            return
        }
        
        let jsonString = toJSONString()
        
        DPDRequest.requestWithURL(baseUrl, endPointURL: endPoint, parameters: nil, method: HTTPMethod.POST, jsonString: jsonString) { (response, responseHeader, error) -> Void in
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
    
    open func updateObject<T: DPDObject>(_ mapper: T.Type, rootUrl: String? = nil, endPoint: String, compblock: @escaping CompletionBlock) {
        let jsonString = toJSONString()
        
        guard let baseUrl = rootUrl ?? DPDConstants.rootUrl else {
            compblock(nil, nil, NSError(domain: "Invalid is required", code: -1, userInfo: nil))
            return
        }
        
        DPDRequest.requestWithURL(baseUrl, endPointURL: endPoint + "/\(self.objectId!)", parameters: nil, method: HTTPMethod.PUT, jsonString: jsonString) { (response, responseHeader, error) -> Void in
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
    
    open func deleteObject(_ rootUrl: String? = nil, endPoint: String, param: [String: AnyObject]? = nil, compblock: @escaping CompletionBlock) {
        
        guard let baseUrl = rootUrl ?? DPDConstants.rootUrl else {
            compblock(nil, nil, NSError(domain: "Invalid is required", code: -1, userInfo: nil))
            return
        }
        
        guard let objectId = self.objectId else {
            compblock([], nil, NSError(domain: "id is required", code: 999, userInfo: nil))
            return
        }
        
        let jsonString = toJSONString()
        
        DPDRequest.requestWithURL(baseUrl, endPointURL: endPoint + "/\(objectId)", parameters: param, method: HTTPMethod.DELETE, jsonString: jsonString) { (response, responseHeader, error) -> Void in
            
            if error == nil {
                print(response ?? "")
                compblock([["message": "Object deleted successfully"]], responseHeader, nil)
            } else {
                compblock([], responseHeader, error)
            }
        }
        
    }
}
