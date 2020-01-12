//
//  DPDRequest.swift
//  DPDSwift
//
//Created by Sylveus, Steeven on 11/8/18.
//

import UIKit

public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case DELETE = "DELETE"
    case PUT = "PUT"
}


let accessTokenHeaderFieldKey = "accessToken"
let sessionTokenKey = "SessionToken"


open class DPDRequest: NSObject {
    
    static let sharedHelper = DPDRequest()
    static var refreshTokenOperation: BackendOperation!
    static var isRefreshTokenRefreshing = false
    static let operationQueue: OperationQueue = {
        var queue = OperationQueue()
        return queue
    }()
    
    var rootUrl = ""
    
    static var operations = [String: BackendOperation]()
    static let API_TIME_OUT_PERIOD      = 30.0
    
    public class func requestWithURL(_ rootURL:String,
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
        
        if let token = DPDHelper.getSessionId() {
            request!.setValue(token, forHTTPHeaderField: "Cookie")
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
        let operation = BackendOperation(session: URLSession.shared, request: request) { (data, response, error) -> Void in
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case DPDConstants.expiredAccessTokenErrorCode
                    where DPDConstants.accessTokenRefreshEndPoint != nil:
                    if !isRefreshTokenRefreshing {
                        print("refreshtokenurl: \(request.url!)")
                        
                        refreshAccessToken((request.url?.absoluteString)!, compBlock: { (response, responseHeader, error) -> Void in
                            if(error == nil) {
                                if let credential = DPDCredentials.sharedCredentials.accessToken {
                                    req.setValue(credential, forHTTPHeaderField: accessTokenHeaderFieldKey)
                                }
                            } else {
                                compBlock(response, nil, error)
                            }
                        })
                    }
                    break
                    
                default:
                    if let url = request.url?.absoluteString {
                        operations.removeValue(forKey: url)
                    }
                    isRefreshTokenRefreshing = false
                    processJsonResponse(data, response: response, error: error, compBlock: compBlock)
                    break;
                }
            } else {
                if let url = request.url?.absoluteString {
                    operations.removeValue(forKey: url)
                }
                isRefreshTokenRefreshing = false
                processJsonResponse(data, response: response, error: error, compBlock: compBlock)
            }
        }
        
        if refreshTokenOperation == nil || refreshTokenOperation.isFinished {
            refreshTokenOperation = operation
        }
        
        if let url = request.url?.absoluteString {
            operations[url] = operation
        }
        
        operationQueue.addOperation(operation)
        
        print("\n\n \(operations)")
    }
    
    class func processJsonResponse(_ data: Data?, response: URLResponse?, error: Error?, compBlock: @escaping CompletionBlock) {
        DispatchQueue.main.async {
            print("\n\nPrinting Operations Count: \(operations.count)")
            if error != nil {
                compBlock(response, nil, error)
            } else {
                if error == nil {
                    var jsonData: Any? = nil
                    
                    do {
                        jsonData = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    } catch {
                        print("Serialization Error: \(error)")
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                            print("**Response***\n\(jsonData != nil ? jsonData! : [])")
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
        
        var urlString = sharedHelper.rootUrl + DPDConstants.accessTokenRefreshEndPoint!;
        print(urlString);
        urlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let url = (URL(string: urlString))
        
        var request = URLRequest(url: url!)
        request.timeoutInterval = API_TIME_OUT_PERIOD
        request.httpMethod = HTTPMethod.GET.rawValue
        
        request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        if let token = DPDHelper.getSessionId() {
            request.setValue(token, forHTTPHeaderField: "Cookie")
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
                            
                            refreshTokenOperation = nil
                            compBlock(jsonData, nil, error)
                            for (_, operation) in operations {
                                print("Remake request with new access token: \(String(describing: operation.request?.url))")
                                operation.start()
                            }
                            operations.removeAll()
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

