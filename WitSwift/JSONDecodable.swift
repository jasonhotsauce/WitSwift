//
//  File.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 5/3/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation
public typealias JSON = [String: AnyObject]

enum JSONDecodingError: ErrorType {
    case ArrayNotDecodable(elementType: Any.Type)
    case DictionaryNotDecodable(elementType: Any.Type)
    case PropertyNotDecodable(elementType: Any.Type)
    case KeyMissing(key: String)
    case ValueNotTransformable(value: Any)

    func toNSError() -> NSError {
        let domain = "ai.wit.json.decodeError"
        switch self {
        case .ArrayNotDecodable(let elementType):
            return NSError(domain: domain, code: 1, userInfo: ["elementType": String(elementType)])
        case .DictionaryNotDecodable(let elementType):
            return NSError(domain: domain, code: 2, userInfo: ["elementType": String(elementType)])
        case .PropertyNotDecodable(let elementType):
            return NSError(domain: domain, code: 3, userInfo: ["elementType": String(elementType)])
        case .KeyMissing(let key):
            return NSError(domain: domain, code: 4, userInfo: ["key": key])
        case .ValueNotTransformable(let value):
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
                throw JSONDecodingError.ArrayNotDecodable(elementType: $0.dynamicType)
            }
            return try Element(json: jsonEle)
            })
    }
}

public struct JSONDecoder {
    var json: JSON

    func decode<Primary: JSONPrimaryType>(key: String) throws -> Primary {
        guard let value = json[key] else {
            throw JSONDecodingError.KeyMissing(key: key)
        }
        guard let result = value as? Primary else {
            throw JSONDecodingError.PropertyNotDecodable(elementType: value.dynamicType)
        }
        return result
    }

    func decode<Primary: JSONPrimaryType>(key: String) -> Primary? {
        return json[key] as? Primary
    }

    func decode<T: JSONDecodable>(key: String) throws -> T {
        guard let value = json[key] else {
            throw JSONDecodingError.KeyMissing(key: key)
        }
        guard let result = value as? T else {
            throw JSONDecodingError.PropertyNotDecodable(elementType: value.dynamicType)
        }
        return result
    }

    func decode<Element: JSONPrimaryType>(key: String) throws -> [Element] {
        guard let value = json[key] else {
            throw JSONDecodingError.KeyMissing(key: key)
        }
        guard let result = value as? [Element] else {
            throw JSONDecodingError.ArrayNotDecodable(elementType: value.dynamicType)
        }
        return result
    }

    func decode<Element: JSONDecodable>(key: String) throws -> [Element] {
        guard let value = json[key] else {
            throw JSONDecodingError.KeyMissing(key: key)
        }
        guard let result = value as? [JSON] else {
            throw JSONDecodingError.ArrayNotDecodable(elementType: value.dynamicType)
        }
        return try result.flatMap{try Element(json: $0)}
    }

    func decode<V: JSONPrimaryType>(key: String) throws -> [String: V] {
        guard let value = json[key] else {
            throw JSONDecodingError.KeyMissing(key: key)
        }

        guard let result = value as? [String: V] else {
            throw JSONDecodingError.DictionaryNotDecodable(elementType: value.dynamicType)
        }
        return result
    }

    func decode<V: JSONDecodable>(key: String) throws -> [String: V] {
        guard let value = json[key] else {
            throw JSONDecodingError.KeyMissing(key: key)
        }
        guard let dictionary = value as? [String: JSON] else {
            throw JSONDecodingError.DictionaryNotDecodable(elementType: value.dynamicType)
        }
        var result = [String: V]()
        try dictionary.forEach{result[$0] = try V(json: $1)}
        return result
    }

    func decode<EncodeType, DecodeType>(key: String, transformer: JSONTransformer<EncodeType, DecodeType>) throws -> DecodeType {
        guard let value = json[key] else {
            throw JSONDecodingError.KeyMissing(key: key)
        }
        guard let trans = value as? EncodeType else {
            throw JSONDecodingError.ValueNotTransformable(value: value.dynamicType)
        }
        guard let result = transformer.decode(trans) else {
            throw JSONDecodingError.ValueNotTransformable(value: value.dynamicType)
        }
        return result
    }
}