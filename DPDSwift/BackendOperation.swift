//
//  BackendOperation.swift
//  Common
//
//  Created by Tayal, Rishabh on 3/10/16.
//  Copyright © 2016 Tayal, Rishabh. All rights reserved.
//

public class BackendOperation: NSOperation {
    
    public typealias OperationCompBlock =  (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void
    
    var task: NSURLSessionTask?
    var request: NSMutableURLRequest?
    var session: NSURLSession?
    var compBlock: OperationCompBlock?
    
    
    private var _executing: Bool = false
    override public var executing: Bool {
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
    override public var finished: Bool {
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
    
    public override init () {
        
    }
    
    public init(session: NSURLSession, request: NSMutableURLRequest, completion: OperationCompBlock) {
        super.init()
        self.request = request
        self.session = session
        self.compBlock = completion
    }
    
    override public func start() {
        if let credential = DPDCredenntials.sharedCredentials.accessToken {
            request?.setValue(credential, forHTTPHeaderField: accessTokenHeaderFieldKey)
        }
        
        self.task = self.session!.dataTaskWithRequest(self.request!, completionHandler: { (d: NSData?, r: NSURLResponse?, e: NSError?) -> Void in
            self.compBlock!(data: d, response: r, error: e)
            self.executing = false
            self.finished = true
        })
        
        task!.resume()
    }
    
    override public func cancel() {
        super.cancel()
        task!.cancel()
    }
}
