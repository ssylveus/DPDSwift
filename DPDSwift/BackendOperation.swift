//
//  BackendOperation.swift
//  Common
//
//  Created by Tayal, Rishabh on 3/10/16.
//  Copyright © 2016 Tayal, Rishabh. All rights reserved.
//

class BackendOperation: Operation {
    
    typealias OperationCompBlock =  (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void
    
    var task: URLSessionDataTask?
    var request: URLRequest?
    var session: URLSession?
    var compBlock: OperationCompBlock?
    
    
    fileprivate var _executing: Bool = false
    override var isExecuting: Bool {
        get { return _executing }
        set {
            if _executing != newValue {
                willChangeValue(forKey: "isExecuting")
                _executing = newValue
                didChangeValue(forKey: "isExecuting")
            }
        }
    }
    
    fileprivate var _finished: Bool = false;
    override  var isFinished: Bool {
        get {
            return _finished
        }
        set {
            if _finished != newValue {
                willChangeValue(forKey: "isFinished")
                _finished = newValue
                didChangeValue(forKey: "isFinished")
            }
        }
    }
    
    override init () {
        
    }
    
    init(session: URLSession, request: URLRequest, completion: @escaping OperationCompBlock) {
        super.init()
        self.request = request
        self.session = session
        self.compBlock = completion
    }
    
    override  func start() {
        if let credential = DPDCredentials.sharedCredentials.accessToken {
            request?.setValue(credential, forHTTPHeaderField: accessTokenHeaderFieldKey)
        }
        self.task = self.session!.dataTask(with: self.request!, completionHandler: { (data, response, error) in
            
            self.compBlock!(data, response, error)
            self.isExecuting = false
            self.isFinished = true

        })
        
        task!.resume()
    }
    
    override  func cancel() {
        super.cancel()
        task!.cancel()
    }
}
