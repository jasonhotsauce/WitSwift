//
//  Converse.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 5/30/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation

public enum ConverseType : String {
    case Merge = "merge"
    case Message = "msg"
    case Action = "action"
    case Stop = "stop"
}

public protocol Conversable {
    var type : ConverseType {get set}
    var msg : String? {get set}
    var action : String? {get set}
    var entities : [JSON]? {get set}
    var confidence : Double {get set}
}

internal struct Converse : Conversable, JSONConvertable, JSONDecodable {
    var type: ConverseType
    var msg: String?
    var action: String?
    var entities: [JSON]?
    var confidence: Double

    init(json: JSON) throws {
        let decoder = JSONDecoder(json: json)
        type = try ConverseType(rawValue: decoder.decode("type"))!
        msg = decoder.decode("msg")
        action = decoder.decode("action")
        entities = json["entities"] as? [JSON]
        confidence = try decoder.decode("confidence")
    }
}