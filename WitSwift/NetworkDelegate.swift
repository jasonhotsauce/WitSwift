//
//  NetworkDelegate.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 4/27/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation

internal class NetworkDelegate : NSObject, URLSessionDataDelegate {
    private let syncQueue = DispatchQueue(label: "wit.ai.networkdelegate.queue", attributes: DispatchQueueAttributes.concurrent)
    private var taskDelegates: [Int: TaskDelegate] = [:]

    subscript(task: URLSessionTask) -> TaskDelegate? {
        get {
            var delegate: TaskDelegate?
            if #available(iOS 10, *) {
                dispatchPrecondition(condition: .notOnQueue(syncQueue))
            }
            syncQueue.sync {
                delegate = self.taskDelegates[task.taskIdentifier]
            }
            return delegate
        }
        set {
            syncQueue.async(flags: .barrier) { 
                self.taskDelegates[task.taskIdentifier] = newValue
            }
        }
    }

    override init() {
        super.init()
    }

    //MARK # Network delegate
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let taskDelegate = self[dataTask]
        taskDelegate?.data.append(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) {
        let taskDelegate = self[task]
        taskDelegate?.completionHandler?(task, taskDelegate?.data, error)
    }
}

internal class TaskDelegate {
    typealias CompletionBlock = (URLSessionTask?, Data?, NSError?) -> Void
    internal var data: Data
    internal let task: URLSessionTask
    internal let completionHandler: CompletionBlock?
    init(task: URLSessionTask, completion: CompletionBlock?) {
        data = Data()
        self.task = task
        completionHandler = completion
    }
}
