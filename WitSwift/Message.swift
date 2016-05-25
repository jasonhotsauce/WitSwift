//
//  Message.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 4/26/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation

public struct Outcome : JSONConvertable, JSONDecodable {
    public var text: String
    public var intent: String
    public var confidence: Double

    public init(json: JSON) throws {
        let decoder = JSONDecoder(json: json)
        text = try decoder.decode("_text")
        intent = try decoder.decode("intent")
        confidence = try decoder.decode("confidence")
    }
}

public struct Message : JSONConvertable, JSONDecodable {
    public var messageID: String
    public var text: String
    public var outcomes: [Outcome]

    public init(json: JSON) throws {
        let decoder = JSONDecoder(json: json)
        messageID = try decoder.decode("msg_id")
        text = try decoder.decode("_text")
        outcomes = try decoder.decode("outcomes")
    }
}

public struct Intent {
    
}