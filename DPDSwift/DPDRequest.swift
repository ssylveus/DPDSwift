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
    case unAuthorizedUser = 401
    case existingSession = 432
    case expiredAccessToken = 433
}


let accessTokenHeaderFieldKey = "accessToken"
let sessionTokenKey = "SessionToken"


class DPDRequest: NSObject {
    
    static let sharedHelper = DPDRequest()
    static var refreshTokenOperation: BackendOperation!
    static var isRefreshTokenRefreshing = false
    static let operationQueue: OperationQueue = {
        var queue = OperationQueue()
        return queue
    }()
    
    var rootUrl = ""
    
    static let API_TIME_OUT_PERIOD      = 30.0
    
    class func requestWithURL(_ rootURL:String,
                              endPointURL: String?,
                              parameters: [String: Any]?,
                              method: HTTPMethod,
                              jsonString: String?,
                              cacheResponse: Bool? = false,
                              requestHeader: [String: AnyObject]? = nil,
                              andCompletionBlock compBlock: @escaping CompletionBlock) {
        
        sharedHelper.rootUrl = rootURL
        var urlString = rootURL + endPointURL!
        if let param = parameters {
            urlString = urlString + "?" + DPDHelper.toJsonString(param)!
        }
        
        print(urlString)
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        let url = (URL(string: urlString))
        var request: URLRequest?
        if cacheResponse == true {
            if DPDHelper.sharedHelper.networkReachable {
                request = URLRequest(url: URL(string: urlString)!, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: API_TIME_OUT_PERIOD)
            } else {
                request = URLRequest(url: URL(string: urlString)!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: API_TIME_OUT_PERIOD)
            }
        } else {
            request = URLRequest(url: url!)
        }
        
        request!.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request!.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let credential = DPDCredentials.sharedCredentials.accessToken {
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
        request!.httpMethod = method.rawValue
        
        if let string = jsonString {
            let postData = NSData(data: string.data(using: String.Encoding.utf8)!) as Data
            request!.httpBody = postData
        }
        
        print(request?.allHTTPHeaderFields ?? "");
        urlSessionFromRequest(request!, compBlock: compBlock)
    }
    
    class func urlSessionFromRequest(_ request: URLRequest, compBlock: @escaping CompletionBlock) {
        var req = request
        let refreshOperation = BackendOperation(session: URLSession.shared, request: request) { (data, response, error) -> Void in
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case ErrorCodes.expiredAccessToken.rawValue:
                    if !isRefreshTokenRefreshing {
                        refreshAccessToken((request.url?.absoluteString)!, compBlock: { (response, responseHeader, error) -> Void in
                            if(error == nil) {
                                if let credential = DPDCredentials.sharedCredentials.accessToken {
                                    req.setValue(credential, forHTTPHeaderField: accessTokenHeaderFieldKey)
                                }
                                urlSessionFromRequest(request, compBlock: { (response, responseHeader, error) -> Void in
                                    urlSessionFromRequest(request, compBlock: compBlock)
                                })
                            } else {
                                compBlock(response, nil, error)
                            }
                        })
                    }
                    break
                    
                default:
                    processJsonResponse(data, response: response, error: error, compBlock: compBlock)
                    break;
                }
            } else {
                processJsonResponse(data, response: response, error: error, compBlock: compBlock)
            }
        }
        
        if refreshTokenOperation == nil || refreshTokenOperation.isFinished {
            refreshTokenOperation = refreshOperation
        }
        
        operationQueue.addOperation(refreshOperation)
    }
    
    class func processJsonResponse(_ data: Data?, response: URLResponse?, error: Error?, compBlock: @escaping CompletionBlock) {
        DispatchQueue.main.async {
            if error != nil {
                compBlock(response, nil, error)
            } else {
                if error == nil {
                    var jsonData: Any? = nil
                    
                    do {
                        jsonData = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    } catch {
                        
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 || httpResponse.statusCode == 201 {
                            compBlock(jsonData != nil ? jsonData! : [], httpResponse.allHeaderFields, error)
                            return
                        } else {
                            var message = ""
                            if let data = jsonData as? [String: AnyObject], let errorMessage = data["message"] as? String {
                                message = errorMessage
                            }
                            
                            let error = NSError(domain: message, code: httpResponse.statusCode, userInfo: nil)
                            compBlock(jsonData, nil, error)
                            return
                        }
                    }
                    
                } else {
                    compBlock(response!, nil, error)
                    return
                }
            }
        }
    }
    
    class func refreshAccessToken(_ forAPI: String, compBlock: @escaping CompletionBlock) {
        print("***************** Refreshing Access Token ********************")
        isRefreshTokenRefreshing = true
        
        var urlString = sharedHelper.rootUrl + "refreshaccesstoken";
        print(urlString);
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let url = (URL(string: urlString))
        
        var request = URLRequest(url: url!)
        request.timeoutInterval = API_TIME_OUT_PERIOD
        request.httpMethod = HTTPMethod.GET.rawValue
        
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        if let token = DPDHelper.retrieveFromUserDefault(sessionTokenKey) as? String {
            request.setValue("sid=\(token)", forHTTPHeaderField: "cookie")
        }
        
        let refreshOperation = BackendOperation(session: URLSession.shared, request: request) { (data, response, error) -> Void in
            
            var jsonData: Any? = nil
            
            do {
                jsonData = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
            } catch {
                
            }
            
            if let data = data {
                do {
                    jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                } catch {
                    compBlock (nil, nil, error)
                    return
                }
            }
            
            if error == nil {
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let response = jsonData as? [String: AnyObject] {
                            if let accessToken = response["accessToken"] as? String {
                                DPDCredentials.sharedCredentials.accessToken = accessToken
                                DPDCredentials.sharedCredentials.save()
                            }
                            isRefreshTokenRefreshing = false
                            refreshTokenOperation = nil
                            compBlock(jsonData, nil, error)
                        }
                    } else {
                        let error = NSError(domain: "Unknown Error", code: httpResponse.statusCode, userInfo: nil)
                        compBlock(jsonData, nil, error)
                        return
                    }
                }
            }
            
        }
        
        if refreshTokenOperation == nil || refreshTokenOperation.isFinished {
            refreshTokenOperation = refreshOperation
        }
        
        operationQueue.addOperation(refreshOperation)
    }
    
}

