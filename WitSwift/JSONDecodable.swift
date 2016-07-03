//
//  File.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 5/3/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation
public typealias JSON = [String: AnyObject]

enum JSONDecodingError: ErrorProtocol, ErrorConvertable {
    case arrayNotDecodable(elementType: Any.Type)
    case dictionaryNotDecodable(elementType: Any.Type)
    case propertyNotDecodable(elementType: Any.Type)
    case keyMissing(key: String)
    case valueNotTransformable(value: Any)

    func toNSError() -> NSError {
        let domain = "ai.wit.json.decodeError"
        switch self {
        case .arrayNotDecodable(let elementType):
            return NSError(domain: domain, code: 1, userInfo: ["elementType": String(elementType)])
        case .dictionaryNotDecodable(let elementType):
            return NSError(domain: domain, code: 2, userInfo: ["elementType": String(elementType)])
        case .propertyNotDecodable(let elementType):
            return NSError(domain: domain, code: 3, userInfo: ["elementType": String(elementType)])
        case .keyMissing(let key):
            return NSError(domain: domain, code: 4, userInfo: ["key": key])
        case .valueNotTransformable(let value):
            return NSError(domain: domain, code: 5, userInfo: ["value": String(value)])
        }
    }
}

public protocol JSONDecodable {
    init(json: JSON) throws
}

extension Array where Element : JSONDecodable {
    init(json: [AnyObject]) throws {
        self.init(try json.flatMap{
            guard let jsonEle = $0 as? JSON else {
                throw JSONDecodingError.arrayNotDecodable(elementType: $0.dynamicType)
            }
            return try Element(json: jsonEle)
            })
    }
}

public struct JSONDecoder {
    var json: JSON

    func decode<Primary: JSONPrimaryType>(_ key: String) throws -> Primary {
        guard let value = json[key] else {
            throw JSONDecodingError.keyMissing(key: key)
        }
        guard let result = value as? Primary else {
            throw JSONDecodingError.propertyNotDecodable(elementType: value.dynamicType)
        }
        return result
    }

    func decode<Primary: JSONPrimaryType>(_ key: String) -> Primary? {
        return json[key] as? Primary
    }

    func decode<T: JSONDecodable>(_ key: String) throws -> T {
        guard let value = json[key] else {
            throw JSONDecodingError.keyMissing(key: key)
        }
        guard let result = value as? T else {
            throw JSONDecodingError.propertyNotDecodable(elementType: value.dynamicType)
        }
        return result
    }

    func decode<Element: JSONPrimaryType>(_ key: String) throws -> [Element] {
        guard let value = json[key] else {
            throw JSONDecodingError.keyMissing(key: key)
        }
        guard let result = value as? [Element] else {
            throw JSONDecodingError.arrayNotDecodable(elementType: value.dynamicType)
        }
        return result
    }

    func decode<Element: JSONDecodable>(_ key: String) throws -> [Element] {
        guard let value = json[key] else {
            throw JSONDecodingError.keyMissing(key: key)
        }
        guard let result = value as? [JSON] else {
            throw JSONDecodingError.arrayNotDecodable(elementType: value.dynamicType)
        }
        return try result.flatMap{try Element(json: $0)}
    }

    func decode<V: JSONPrimaryType>(_ key: String) throws -> [String: V] {
        guard let value = json[key] else {
            throw JSONDecodingError.keyMissing(key: key)
        }

        guard let result = value as? [String: V] else {
            throw JSONDecodingError.dictionaryNotDecodable(elementType: value.dynamicType)
        }
        return result
    }

    func decode<V: JSONDecodable>(_ key: String) throws -> [String: V] {
        guard let value = json[key] else {
            throw JSONDecodingError.keyMissing(key: key)
        }
        guard let dictionary = value as? [String: JSON] else {
            throw JSONDecodingError.dictionaryNotDecodable(elementType: value.dynamicType)
        }
        var result = [String: V]()
        try dictionary.forEach{result[$0] = try V(json: $1)}
        return result
    }

    func decode<EncodeType, DecodeType>(_ key: String, transformer: JSONTransformer<EncodeType, DecodeType>) throws -> DecodeType {
        guard let value = json[key] else {
            throw JSONDecodingError.keyMissing(key: key)
        }
        guard let trans = value as? EncodeType else {
            throw JSONDecodingError.valueNotTransformable(value: value.dynamicType)
        }
        guard let result = transformer.decode(trans) else {
            throw JSONDecodingError.valueNotTransformable(value: value.dynamicType)
        }
        return result
    }
}
