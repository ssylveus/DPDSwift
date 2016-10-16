//
//  DPDRequest.swift
//  DPDSwift
//
//  Created by Steeven Sylveus (Contractor) on 10/16/16.
//  Copyright © 2016 Steeven Sylveus. All rights reserved.
//

import UIKit

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case DELETE = "DELETE"
    case PUT = "PUT"
}

enum ErrorCodes: Int {
    case UnAuthorizedUser = 401
    case ExistingSession = 402
    case ExpiredAccessToken = 405
}


let accessTokenHeaderFieldKey = "accessToken"
let sessionTokenKey = "SessionToken"


public class DPDRequest: NSObject {

    static let sharedHelper = DPDRequest()
    static var refreshTokenOperation: BackendOperation!
    static let operationQueue: NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    var rootUrl = ""
    
    static let API_TIME_OUT_PERIOD      = 30.0
    
    class func requestWithURL(rootURL:String,
                              endPointURL: String?,
                              parameters: [String: AnyObject]?,
                              method: HTTPMethod,
                              jsonString: String?,
                              cacheResponse: Bool? = false,
                              requestHeader: [String: AnyObject]? = nil,
                              andCompletionBlock compBlock: CompletionBlock) {
        
        sharedHelper.rootUrl = rootURL
        var urlString = rootURL + endPointURL!
        if let param = parameters {
            urlString = urlString + "?" + DPDHelper.toJsonString(param)!
        }
        
        print(urlString)
        urlString = urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        
        let url = (NSURL(string: urlString))
        var request: NSMutableURLRequest?
        if cacheResponse == true {
            if DPDHelper.sharedHelper.networkReachable {
                request = NSMutableURLRequest(URL: NSURL(string: urlString)!, cachePolicy: .ReturnCacheDataElseLoad, timeoutInterval: API_TIME_OUT_PERIOD)
            } else {
                request = NSMutableURLRequest(URL: NSURL(string: urlString)!, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: API_TIME_OUT_PERIOD)
            }
        } else {
            request = NSMutableURLRequest(URL: url!)
        }
        
        request!.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request!.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let credential = DPDCredenntials.sharedCredentials.accessToken {
            request?.setValue(credential, forHTTPHeaderField: accessTokenHeaderFieldKey)
        }
        
        if let token = DPDHelper.retrieveFromUserDefault(sessionTokenKey) as? String {
            request!.setValue("sid=\(token)", forHTTPHeaderField: "cookie")
        }
        
        if let header = requestHeader {
            for (key, value) in header {
                request!.setValue(value as? String, forHTTPHeaderField: key)
            }
        }
        request!.timeoutInterval = API_TIME_OUT_PERIOD
        request!.HTTPMethod = method.rawValue
        
        if let string = jsonString {
            let postData = NSMutableData(data: string.dataUsingEncoding(NSUTF8StringEncoding)!)
            request!.HTTPBody = postData
        }
        
        print(request?.allHTTPHeaderFields);
        urlSessionFromRequest(request!, compBlock: compBlock)
    }
    
    class func urlSessionFromRequest(request: NSMutableURLRequest, compBlock: CompletionBlock) {
        
        let requestOperation = BackendOperation(session: NSURLSession.sharedSession(), request: request) { (data, response, error) -> Void in
            
            if let httpResponse = response as? NSHTTPURLResponse {
                switch httpResponse.statusCode {
                case ErrorCodes.ExpiredAccessToken.rawValue:
                    refreshAccessToken((request.URL?.absoluteString)!, compBlock: { (response, responseHeader, error) -> Void in
                        if(error == nil) {
                            if let credential = DPDCredenntials.sharedCredentials.accessToken {
                                request.setValue(credential, forHTTPHeaderField: accessTokenHeaderFieldKey)
                            }
                            urlSessionFromRequest(request, compBlock: { (response, responseHeader, error) -> Void in
                                urlSessionFromRequest(request, compBlock: compBlock)
                            })
                        } else {
                            compBlock(response: response, responseHeader: nil, error: error)
                        }
                    })
                    break
                    
                default:
                    processJsonResponse(data, response: response, error: error, compBlock: compBlock)
                    break;
                }
            } else {
                processJsonResponse(data, response: response, error: error, compBlock: compBlock)
            }
        }
        
        if requestOperation != refreshTokenOperation && refreshTokenOperation != nil {
            requestOperation.addDependency(refreshTokenOperation)
        }
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.addOperation(requestOperation)
    }
    
    class func processJsonResponse(data: NSData?, response: NSURLResponse?, error: NSError?, compBlock: CompletionBlock) {
        if error != nil {
            compBlock(response: response, responseHeader: nil, error: error)
        } else {
            if error == nil {
                var jsonData: AnyObject? = nil
                if let data = data {
                    jsonData = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                }
                if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 || httpResponse.statusCode == 201 {
                        compBlock(response: jsonData!, responseHeader: httpResponse.allHeaderFields, error: error)
                        return
                    } else {
                        let error = NSError(domain: "Unknown Error", code: httpResponse.statusCode, userInfo: nil)
                        compBlock(response: jsonData, responseHeader: nil, error: error)
                        return
                    }
                }
                
            } else {
                compBlock(response: response!, responseHeader: nil, error: error)
                return
            }
        }
    }
    
    class func refreshAccessToken(forAPI: String, compBlock: CompletionBlock) {
        
        var urlString = sharedHelper.rootUrl + "refreshaccesstoken";
        print(urlString);
        urlString = urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        let url = (NSURL(string: urlString))
        
        let request = NSMutableURLRequest(URL: url!)
        request.timeoutInterval = API_TIME_OUT_PERIOD
        request.HTTPMethod = HTTPMethod.GET.rawValue
        
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        if let token = DPDHelper.retrieveFromUserDefault(sessionTokenKey) as? String {
            request.setValue("sid=\(token)", forHTTPHeaderField: "cookie")
        }
        
        let refreshOperation = BackendOperation(session: NSURLSession.sharedSession(), request: request) { (data, response, error) -> Void in
            
            var jsonData: AnyObject? = nil
            if let data = data {
                jsonData = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            }
            
            if error == nil {
                if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let response = jsonData as? [String: AnyObject] {
                            if let accessToken = response["accessToken"] as? String {
                                DPDCredenntials.sharedCredentials.accessToken = accessToken
                                DPDCredenntials.sharedCredentials.save()
                            }
                            
                            compBlock(response: jsonData, responseHeader: nil, error: error)
                        }
                    } else {
                        let error = NSError(domain: "Unknown Error", code: httpResponse.statusCode, userInfo: nil)
                        compBlock(response: jsonData, responseHeader: nil, error: error)
                        return
                    }
                }
            }
            
        }
        
        if refreshTokenOperation == nil || refreshTokenOperation.finished {
            refreshTokenOperation = refreshOperation
        }
        
        for backendOperation: BackendOperation in (operationQueue.operations as? [BackendOperation])! {
            backendOperation.addDependency(refreshOperation);
        }
        
        operationQueue.addOperation(refreshOperation)
        operationQueue.maxConcurrentOperationCount = 1
    }
}
