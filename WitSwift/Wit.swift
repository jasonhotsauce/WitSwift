//
//  Wit.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 4/27/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation

public let witErrorDomain = "ai.Wit.error"

private enum WitError : ErrorType {
    case NotValidResponse(response: AnyObject)

    func toNSError() -> NSError {
        switch self {
        case .NotValidResponse(let response):
            return NSError.init(domain: witErrorDomain, code: 1, userInfo: ["response": response])
        }
    }
}

public typealias RequestCompletion = (Bool, Message?, NSError?) -> Void

public func getIntent(configuration: Configurable, query: String, context: Contextable = Context(), messageID: String?, threadID: String?, numberOfOutcome outcome: Int = 1, completion: RequestCompletion?) {
    let path = "/message"
    var param = [String: Any]()
    param["q"] = query
    if let msgID = messageID {
        param["msg_id"] = msgID
    }
    if let notNilThreadID = threadID {
        param["thread_id"] = notNilThreadID
    }
    param["n"] = outcome
    do {
        let contextDictionary = try context.toJSON()
        param["context"] = contextDictionary
        param["v"] = configuration.version
        NetworkManager.sharedInstance.execute(path, method: .Get, param: param, configuration: configuration, completion: { (task, response, error) in
            if let notNilError = error {
                completion?(false, nil, notNilError)
            } else {
                guard let notNilResponse = response else {
                    completion?(true, nil, nil)
                    return
                }
                do {
                    let responseDictionary = try NSJSONSerialization.JSONObjectWithData(notNilResponse, options: .AllowFragments)
                    guard let jsonResponse = responseDictionary as? JSON else {
                        completion?(false, nil, WitError.NotValidResponse(response: responseDictionary).toNSError())
                        return
                    }
                    let message = try Message.init(json: jsonResponse)
                    dispatch_async(dispatch_get_main_queue(), { 
                        completion?(true, message, nil)
                    })
                } catch let error as NSError {
                    dispatch_async(dispatch_get_main_queue(), { 
                        completion?(false, nil, error);
                    })
                }
            }
        })
    } catch let error as NSError {
        dispatch_async(dispatch_get_main_queue(), { 
            completion?(false, nil, error)
        })
    }
}