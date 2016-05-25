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
    case Authentication = "Authentication"
    case ContentType = "Content-Type"
    case AcceptType = "Accept"
    case AcceptEncoding = "Accept-Encoding"
}

internal protocol RequestConstruction {
    associatedtype Request
    static func constructRequest(url: NSURL, method: HTTPRequestMethod, body: NSData?, token: String) -> Request
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

    func execute(urlPath: String, method: HTTPRequestMethod, param: [String: Any]?, configuration: Configurable, completion: (( NSURLSessionTask?, NSData?, NSError?) ->Void)?)
    {
        guard let url = NSURL(string: urlPath, relativeToURL: baseURL) else {
            completion?(nil, nil, nil)
            return
        }
        let jsonOption = NSJSONWritingOptions()
        var data: NSData?
        if let jsonBody = param as? AnyObject {
            do {
                data = try NSJSONSerialization.dataWithJSONObject(jsonBody, options: jsonOption)
            } catch let error as NSError {
                completion?(nil, nil, error)
            }
        }
        let request = NSURLRequest.constructRequest(url, method: method, body: data, token: configuration.token)
        let task = session.dataTaskWithRequest(request)
        delegate[task] = TaskDelegate(task: task, completion: completion)
        task.resume()
    }
}

extension NSURLRequest : RequestConstruction {
    typealias Request = NSURLRequest
    static func constructRequest(url: NSURL, method: HTTPRequestMethod, body: NSData?, token: String) -> Request {
        let request = NSMutableURLRequest(URL: url, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: 60)
        request.setValue("Bearer \(token)", forHTTPHeaderField: HTTPHeaderField.Authentication.rawValue)
        request.HTTPMethod = method.rawValue
        request.HTTPBody = body
        return request.copy() as! NSURLRequest
    }
}