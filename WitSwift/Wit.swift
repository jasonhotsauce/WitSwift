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
                    guard let jsonResponse = try responseToJSON(notNilResponse) else {
                        return
                    }

                    if let errorString = jsonResponse["error"] as? String {
                        dispatch_async(dispatch_get_main_queue(), { 
                            completion?(false, nil, NSError(domain: witErrorDomain, code: 2, userInfo: ["error": errorString]))
                        })
                        return
                    }

                    let message = try Message.init(json: jsonResponse)
                    dispatch_async(dispatch_get_main_queue(), { 
                        completion?(true, message, nil)
                    })
                } catch let witError as WitError {
                    dispatch_async(dispatch_get_main_queue(), {
                        completion?(false, nil, witError.toNSError())
                    })
                } catch let jsonError as JSONDecodingError {
                    dispatch_async(dispatch_get_main_queue(), {
                        completion?(false, nil, jsonError.toNSError())
                    })
                } catch let error as NSError {
                    dispatch_async(dispatch_get_main_queue(), { 
                        completion?(false, nil, error);
                    })
                }
            }
        })
    } catch let jsonEncodingError as JSONEncodingError {
        dispatch_async(dispatch_get_main_queue(), { 
            completion?(false, nil, jsonEncodingError.toNSError())
        })
    } catch let error as NSError {
        dispatch_async(dispatch_get_main_queue(), {
            completion?(false, nil, error)
        })
    }
}

public typealias ConverseResponseHanlder = (Conversable) -> Contextable?
public typealias ConverseRequestErrorHandler = (NSError) -> Void
public var converseHandler : ConverseResponseHanlder?

public func getConverse(configuration: Configurable, query: String?, sessionID: String, context: Contextable = Context(), maxStep: Double, requestErrorHandler: ConverseRequestErrorHandler?) {
    if maxStep <= 0 {
        return
    }
    let path = "/converse"
    var param = [String: Any]()
    if let notNilQuery = query {
        param["q"] = notNilQuery
    }
    param["sessionID"] = sessionID
    do {
        let contextDictionary = try context.toJSON()
        param["context"] = contextDictionary
        NetworkManager.sharedInstance.execute(path, method: .Post, param: param, configuration: configuration, completion: { (task, responseData, error) in
            if let responseError = error {
                requestErrorHandler?(responseError)
            } else {
                guard let validResponse = responseData else {
                    return
                }
                do {
                    guard let jsonResponse = try responseToJSON(validResponse) else {
                        return
                    }
                    let converse = try Converse.init(json: jsonResponse)
                    if converse.type == .Stop {
                        return
                    }
                    let newContext = converseHandler?(converse) ?? Context()
                    getConverse(configuration, query: nil, sessionID: sessionID, context: newContext, maxStep: maxStep-1, requestErrorHandler: requestErrorHandler)
                } catch let witError as WitError {
                    dispatch_async(dispatch_get_main_queue(), { 
                        requestErrorHandler?(witError.toNSError())
                    })
                } catch let jsonError as JSONDecodingError {
                    dispatch_async(dispatch_get_main_queue(), { 
                        requestErrorHandler?(jsonError.toNSError())
                    })
                } catch let error as NSError {
                    dispatch_async(dispatch_get_main_queue(), {
                        requestErrorHandler?(error)
                    })
                }
            }
        })
    } catch let encodingError as JSONEncodingError {
        dispatch_async(dispatch_get_main_queue(), { 
            requestErrorHandler?(encodingError.toNSError())
        })
    } catch let error as NSError {
        dispatch_async(dispatch_get_main_queue(), { 
            requestErrorHandler?(error)
        })
    }
}

private func responseToJSON(response: NSData) throws -> JSON? {
    let responseDictionary = try NSJSONSerialization.JSONObjectWithData(response, options: .AllowFragments)
    guard let jsonResponse = responseDictionary as? JSON else {
        throw WitError.NotValidResponse(response: responseDictionary)
    }
    return jsonResponse
}
