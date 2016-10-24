//
//  BackendOperation.swift
//  Common
//
//  Created by Tayal, Rishabh on 3/10/16.
//  Copyright © 2016 Tayal, Rishabh. All rights reserved.
//

class BackendOperation: NSOperation {
    
    typealias OperationCompBlock =  (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void
    
    var task: NSURLSessionTask?
    var request: NSMutableURLRequest?
    var session: NSURLSession?
    var compBlock: OperationCompBlock?
    
    
    private var _executing: Bool = false
    override var executing: Bool {
        get { return _executing }
        set {
            if _executing != newValue {
                willChangeValueForKey("isExecuting")
                _executing = newValue
                didChangeValueForKey("isExecuting")
            }
        }
    }
    
    private var _finished: Bool = false;
    override  var finished: Bool {
        get {
            return _finished
        }
        set {
            if _finished != newValue {
                willChangeValueForKey("isFinished")
                _finished = newValue
                didChangeValueForKey("isFinished")
            }
        }
    }
    
    override init () {
        
    }
    
    init(session: NSURLSession, request: NSMutableURLRequest, completion: OperationCompBlock) {
        super.init()
        self.request = request
        self.session = session
        self.compBlock = completion
    }
    
    override  func start() {
        if let credential = DPDCredentials.sharedCredentials.accessToken {
            request?.setValue(credential, forHTTPHeaderField: accessTokenHeaderFieldKey)
        }
        
        self.task = self.session!.dataTaskWithRequest(self.request!, completionHandler: { (d: NSData?, r: NSURLResponse?, e: NSError?) -> Void in
            self.compBlock!(data: d, response: r, error: e)
            self.executing = false
            self.finished = true
        })
        
        task!.resume()
    }
    
    override  func cancel() {
        super.cancel()
        task!.cancel()
    }
}
