//
//  NetworkDelegate.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 4/27/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation

internal class NetworkDelegate: NSObject, NSURLSessionDataDelegate {
    private let syncQueue = dispatch_queue_create("wit.ai.networkdelegate.queue", DISPATCH_QUEUE_CONCURRENT)
    private var taskDelegates: [Int: TaskDelegate] = [:]

    subscript(task: NSURLSessionTask) -> TaskDelegate? {
        get {
            var delegate: TaskDelegate?
            dispatch_sync(syncQueue) { 
                delegate = self.taskDelegates[task.taskIdentifier]
            }
            return delegate
        }
        set {
            dispatch_barrier_async(syncQueue) { 
                self.taskDelegates[task.taskIdentifier] = newValue
            }
        }
    }

    override init() {
        super.init()
    }

    //MARK # Network delegates
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        if let taskDelegate = self[dataTask] {
            taskDelegate.URLSession(session, dataTask: dataTask, didReceiveData: data)
        }
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let taskDelegate = self[task] {
            taskDelegate.URLSession(session, task: task, didCompleteWithError: error)
        }
    }
}

internal class TaskDelegate: NSObject, NSURLSessionDataDelegate {
    typealias CompletionBlock = (NSURLSessionTask?, NSData?, NSError?) -> Void
    private var mutableData: NSMutableData
    private var task: NSURLSessionTask
    private var completionHandler: CompletionBlock?
    init(task: NSURLSessionTask, completion: CompletionBlock?) {
        mutableData = NSMutableData()
        self.task = task
        completionHandler = completion
        super.init()
    }

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        mutableData.appendData(data)
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        completionHandler?(task, mutableData, error)
    }
}