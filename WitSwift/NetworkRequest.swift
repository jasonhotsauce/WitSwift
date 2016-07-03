//
//  NetworkRequest.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 7/3/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation

internal protocol RequestConstruction {
    associatedtype Request
    static func constructRequest(_ url: URL, method: HTTPRequestMethod, params: [String: AnyObject]?, token: String) -> Request
}

extension URLRequest : RequestConstruction {
    typealias Request = URLRequest
    enum RequestQueryKey : String {
        case SessionID = "session_id"
        case UserQuery = "q"
        case Version = "v"
    }

    static func constructRequest(_ url: URL, method: HTTPRequestMethod, params: [String: AnyObject]?, token: String) -> Request {
        let request = NSMutableURLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
        request.setValue("Bearer \(token)", forHTTPHeaderField: HTTPHeaderField.Authentication.rawValue)
        request.httpMethod = method.rawValue
        guard let params = params else {
            return request.copy() as! URLRequest
        }
        switch method {
        case .Get:
            request.url = encodeQuery(request.url!, params: params)
        case .Post, .Put, .Delete:
            var queries = [String: AnyObject]()
            var mutableParams = params
            if let sessionID = params[RequestQueryKey.SessionID.rawValue] {
                queries[RequestQueryKey.SessionID.rawValue] = sessionID
                mutableParams.removeValue(forKey: RequestQueryKey.SessionID.rawValue)
            }
            if let userQuery = params[RequestQueryKey.UserQuery.rawValue] {
                queries[RequestQueryKey.UserQuery.rawValue] = userQuery
                mutableParams.removeValue(forKey: RequestQueryKey.UserQuery.rawValue)
            }
            if let version = params[RequestQueryKey.Version.rawValue] {
                queries[RequestQueryKey.Version.rawValue] = version
                mutableParams.removeValue(forKey: RequestQueryKey.Version.rawValue)
            }
            request.url = encodeQuery(request.url!, params: queries)
            guard let body = try? JSONSerialization.data(withJSONObject: mutableParams, options: JSONSerialization.WritingOptions()) else {
                return request.copy() as! URLRequest
            }
            request.httpBody = body
        }

        return request.copy() as! URLRequest
    }

    private static func encodeQuery(_ url: URL, params: [String: AnyObject]) -> URL {
        if var urlComponents = URLComponents(url:url, resolvingAgainstBaseURL: false) where !params.isEmpty {
            let encodedQuery = (urlComponents.percentEncodedQuery ?? "") + query(params)
            urlComponents.percentEncodedQuery = encodedQuery
            return urlComponents.url ?? url
        }
        return url
    }

    private static func query(_ param: [String : AnyObject]) -> String {
        var components = [(String, String)]()
        for (key, value) in param {
            components += buildComponents(key, value)
        }
        return (components.map{"\($0)=\($1)"} as [String]).joined(separator: "&")
    }

    private static func buildComponents(_ key: String, _ value: AnyObject) -> [(String, String)] {
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
            components.append((key.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) ?? "", value as! String))
        }
        return components
    }
}
