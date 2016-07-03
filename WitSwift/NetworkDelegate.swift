//
//  NetworkDelegate.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 4/27/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation

internal class NetworkDelegate: NSObject, URLSessionDataDelegate {
    private let syncQueue = DispatchQueue(label: "wit.ai.networkdelegate.queue", attributes: DispatchQueueAttributes.concurrent)
    private var taskDelegates: [Int: TaskDelegate] = [:]

    subscript(task: URLSessionTask) -> TaskDelegate? {
        get {
            var delegate: TaskDelegate?
            sync Queue.sync { 
                delegate = self.taskDelegates[task.taskIdentifier]
            }
            return delegate
        }
        set {
            sync Queue.async { 
                self.taskDelegates[task.taskIdentifier] = newValue
            }
        }
    }

    override init() {
        super.init()
    }

    //MARK # Network delegate
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let taskDelegate = self[dataTask] {
            taskDelegate.urlSession(session, dataTask: dataTask, didReceive: data)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) {
        if let taskDelegate = self[task] {
            taskDelegate.urlSession(session, task: task, didCompleteWithError: error)
        }
    }
}

internal class TaskDelegate: NSObject, URLSessionDataDelegate {
    typealias CompletionBlock = (URLSessionTask?, Data?, NSError?) -> Void
    private var mutableData: NSMutableData
    private var task: URLSessionTask
    private var completionHandler: CompletionBlock?
    init(task: URLSessionTask, completion: CompletionBlock?) {
        mutableData = NSMutableData()
        self.task = task
        completionHandler = completion
        super.init()
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        mutableData.append(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) {
        completionHandler?(task, mutableData as Data, error)
    }
}
