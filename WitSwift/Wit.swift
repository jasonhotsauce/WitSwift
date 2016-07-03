//
//  Wit.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 4/27/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation

public let witErrorDomain = "ai.Wit.error"

private enum WitError : ErrorProtocol, ErrorConvertable {
    case notValidResponse(response: AnyObject)

    func toNSError() -> NSError {
        switch self {
        case .notValidResponse(let response):
            return NSError.init(domain: witErrorDomain, code: 1, userInfo: ["response": response])
        }
    }
}

public typealias RequestCompletion = (Bool, Message?, NSError?) -> Void

public func getIntent(_ configuration: Configurable, query: String, context: Contextable = Context(), messageID: String?, threadID: String?, numberOfOutcome outcome: Int = 1, completion: RequestCompletion?) {
    let path = "/message"
    var params = [String: AnyObject]()
    params["q"] = query
    if let msgID = messageID {
        params["msg_id"] = msgID
    }
    if let notNilThreadID = threadID {
        params["thread_id"] = notNilThreadID
    }
    params["n"] = outcome
    do {
        let contextDictionary = try context.toJSON()
        params["context"] = contextDictionary
        params["v"] = configuration.version
        NetworkManager.sharedInstance.execute(path, HTTPMethod: .Get, params: params, configuration: configuration, completion: { (task, response, error) in
            if let notNilError = error {
                completion?(false, nil, notNilError)
            } else {
                guard let notNilResponse = response else {
                    completion?(true, nil, nil)
                    return
                }
                do {
                    guard let jsonResponse = try notNilResponse.toJson() else {
                        return
                    }

                    if let errorString = jsonResponse["error"] as? String {
                        DispatchQueue.main.async(execute: { 
                            completion?(false, nil, NSError(domain: witErrorDomain, code: 2, userInfo: ["error": errorString]))
                        })
                        return
                    }

                    let message = try Message.init(json: jsonResponse)
                    DispatchQueue.main.async(execute: { 
                        completion?(true, message, nil)
                    })
                } catch let witError as WitError {
                    DispatchQueue.main.async(execute: {
                        completion?(false, nil, witError.toNSError())
                    })
                } catch let jsonError as JSONDecodingError {
                    DispatchQueue.main.async(execute: {
                        completion?(false, nil, jsonError.toNSError())
                    })
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: { 
                        completion?(false, nil, error);
                    })
                }
            }
        })
    } catch let jsonEncodingError as JSONEncodingError {
        DispatchQueue.main.async(execute: { 
            completion?(false, nil, jsonEncodingError.toNSError())
        })
    } catch let error as NSError {
        DispatchQueue.main.async(execute: {
            completion?(false, nil, error)
        })
    }
}

public typealias ConverseResponseHanlder = (Conversable) -> Contextable?
public typealias ConverseRequestErrorHandler = (NSError) -> Void
public var converseHandler : ConverseResponseHanlder?

public func getConverse(_ configuration: Configurable, query: String?, sessionID: String, context: Contextable = Context(), maxStep: Double, requestErrorHandler: ConverseRequestErrorHandler?) {
    if maxStep <= 0 {
        return
    }
    let path = "/converse"
    var params = [String: AnyObject]()
    if let notNilQuery = query {
        params["q"] = notNilQuery
    }
    params["session_id"] = sessionID
    do {
        let contextDictionary = try context.toJSON()
        params["context"] = contextDictionary
        NetworkManager.sharedInstance.execute(path, HTTPMethod: .Post, params: params, configuration: configuration, completion: { (task, responseData, error) in
            if let responseError = error {
                requestErrorHandler?(responseError)
            } else {
                guard let validResponse = responseData else {
                    return
                }
                do {
                    guard let jsonResponse = try validResponse.toJson() else {
                        return
                    }
                    let converse = try Converse.init(json: jsonResponse)
                    if converse.type == .Stop {
                        return
                    }
                    let newContext = converseHandler?(converse) ?? Context()
                    getConverse(configuration, query: nil, sessionID: sessionID, context: newContext, maxStep: maxStep-1, requestErrorHandler: requestErrorHandler)
                } catch let witError as WitError {
                    DispatchQueue.main.async(execute: { 
                        requestErrorHandler?(witError.toNSError())
                    })
                } catch let jsonError as JSONDecodingError {
                    DispatchQueue.main.async(execute: { 
                        requestErrorHandler?(jsonError.toNSError())
                    })
                } catch let error as NSError {
                    DispatchQueue.main.async(execute: {
                        requestErrorHandler?(error)
                    })
                }
            }
        })
    } catch let encodingError as JSONEncodingError {
        DispatchQueue.main.async(execute: { 
            requestErrorHandler?(encodingError.toNSError())
        })
    } catch let error as NSError {
        DispatchQueue.main.async(execute: { 
            requestErrorHandler?(error)
        })
    }
}

extension Data {
    func toJson() throws -> JSON? {
        let responseDictionary = try JSONSerialization.jsonObject(with: self, options: .allowFragments)
        guard let jsonResponse = responseDictionary as? JSON else {
            throw WitError.notValidResponse(response: responseDictionary)
        }
        return jsonResponse
    }
}
