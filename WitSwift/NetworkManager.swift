//
//  NetworkManager.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 4/25/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation

enum HTTPRequestMethod: String {
    case Get = "GET"
    case Post = "POST"
    case Put = "Put"
    case Delete = "DELETE"
}

enum HTTPHeaderField: String {
    case Authentication = "Authorization"
    case ContentType = "Content-Type"
    case AcceptType = "Accept"
    case AcceptEncoding = "Accept-Encoding"
}

internal protocol RequestConstruction {
    associatedtype Request
    static func constructRequest(url: NSURL, method: HTTPRequestMethod, params: [String: AnyObject]?, token: String) -> Request
}

internal final class NetworkManager: NSObject, NSURLSessionTaskDelegate {
    let baseURL = NSURL(string: "https://api.wit.ai/")

    static let sharedInstance : NetworkManager = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = defaultHTTPHeaders
        return NetworkManager(configuration: configuration)
    }()

    static let defaultHTTPHeaders: [String: String] = {
        let acceptEncoding = "gzip;q=1.0, compress;q=0.5"
        return [HTTPHeaderField.AcceptEncoding.rawValue: acceptEncoding, HTTPHeaderField.ContentType.rawValue: "application/json", HTTPHeaderField.AcceptType.rawValue: "application/json"]
    }()

    let session: NSURLSession
    let delegate: NetworkDelegate

    init(configuration: NSURLSessionConfiguration, delegate: NetworkDelegate = NetworkDelegate()) {
        self.delegate = delegate
        session = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    func execute(urlPath: String, method: HTTPRequestMethod, params: [String: AnyObject]?, configuration: Configurable, completion: (( NSURLSessionTask?, NSData?, NSError?) ->Void)?)
    {
        guard let url = NSURL(string: urlPath, relativeToURL: baseURL) else {
            completion?(nil, nil, nil)
            return
        }

        let request = NSURLRequest.constructRequest(url, method: method, params: params, token: configuration.token)
        let task = session.dataTaskWithRequest(request)
        delegate[task] = TaskDelegate(task: task, completion: completion)
        task.resume()
    }
}

extension NSURLRequest : RequestConstruction {
    typealias Request = NSURLRequest
    enum RequestQueryKey : String {
        case SessionID = "session_id"
        case UserQuery = "q"
        case Version = "v"
    }

    static func constructRequest(url: NSURL, method: HTTPRequestMethod, params: [String: AnyObject]?, token: String) -> Request {
        let request = NSMutableURLRequest(URL: url, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 60)
        request.setValue("Bearer \(token)", forHTTPHeaderField: HTTPHeaderField.Authentication.rawValue)
        request.HTTPMethod = method.rawValue
        guard let params = params else {
            return request.copy() as! NSURLRequest
        }
        switch method {
        case .Get:
            request.URL = encodeQuery(request.URL!, params: params)
        case .Post, .Put, .Delete:
            var queries = [String: AnyObject]()
            var mutableParams = params
            if let sessionID = params[RequestQueryKey.SessionID.rawValue] {
                queries[RequestQueryKey.SessionID.rawValue] = sessionID
                mutableParams.removeValueForKey(RequestQueryKey.SessionID.rawValue)
            }
            if let userQuery = params[RequestQueryKey.UserQuery.rawValue] {
                queries[RequestQueryKey.UserQuery.rawValue] = userQuery
                mutableParams.removeValueForKey(RequestQueryKey.UserQuery.rawValue)
            }
            if let version = params[RequestQueryKey.Version.rawValue] {
                queries[RequestQueryKey.Version.rawValue] = version
                mutableParams.removeValueForKey(RequestQueryKey.Version.rawValue)
            }
            request.URL = encodeQuery(request.URL!, params: queries)
            guard let body = try? NSJSONSerialization.dataWithJSONObject(mutableParams, options: NSJSONWritingOptions()) else {
                return request.copy() as! NSURLRequest
            }
            request.HTTPBody = body
        }

        return request.copy() as! NSURLRequest
    }

    static func encodeQuery(url: NSURL, params: [String: AnyObject]) -> NSURL {
        if let urlComponents = NSURLComponents(URL:url, resolvingAgainstBaseURL: false) where !params.isEmpty {
            let encodedQuery = (urlComponents.percentEncodedQuery ?? "") + query(params)
            urlComponents.percentEncodedQuery = encodedQuery
            return urlComponents.URL ?? url
        }
        return url
    }

    static func query(param: [String : AnyObject]) -> String {
        var components = [(String, String)]()
        for (key, value) in param {
            components += buildComponents(key, value)
        }
        return (components.map{"\($0)=\($1)"} as [String]).joinWithSeparator("&")
    }

    static func buildComponents(key: String, _ value: AnyObject) -> [(String, String)] {
        var components = [(String, String)]()
        if let array = value as? [AnyObject] {
            for arrVal in array {
                components += buildComponents("\(key)[]", arrVal)
            }
        } else if let dictionary = value as? [String: AnyObject] {
            for (childKey, childValue) in dictionary {
                components += buildComponents("\(key)[\(childKey)]", childValue)
            }
        } else {
            components.append((key.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet()) ?? "", value as! String))
        }
        return components
    }
}