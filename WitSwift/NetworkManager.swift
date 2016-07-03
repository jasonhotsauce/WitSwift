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

internal final class NetworkManager: NSObject, URLSessionTaskDelegate {
    let baseURL = URL(string: "https://api.wit.ai/")

    static let sharedInstance : NetworkManager = {
        let configuration = URLSessionConfiguration.default()
        configuration.httpAdditionalHeaders = defaultHTTPHeaders
        return NetworkManager(configuration: configuration)
    }()

    private static let defaultHTTPHeaders: [String: String] = {
        let acceptEncoding = "gzip;q=1.0, compress;q=0.5"
        return [HTTPHeaderField.AcceptEncoding.rawValue: acceptEncoding, HTTPHeaderField.ContentType.rawValue: "application/json", HTTPHeaderField.AcceptType.rawValue: "application/json"]
    }()

    let session: URLSession
    let delegate: NetworkDelegate

    init(configuration: URLSessionConfiguration, delegate: NetworkDelegate = NetworkDelegate()) {
        self.delegate = delegate
        session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    func execute(_ urlPath: String, HTTPMethod method: HTTPRequestMethod, params: [String: AnyObject]?, configuration: Configurable, completion: (( URLSessionTask?, Data?, NSError?) ->Void)?)
    {
        guard let url = URL(string: urlPath, relativeTo: baseURL!) else {
            completion?(nil, nil, nil)
            return
        }

        let request = URLRequest.constructRequest(url, method: method, params: params, token: configuration.token)
        let task = session.dataTask(with: request)
        delegate[task] = TaskDelegate(task: task, completion: completion)
        task.resume()
    }
}
