//
//  JSONConvertable.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 4/29/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation

enum JSONEncodingError: ErrorType {
    case ArrayIncompatible(elementType: Any.Type)
    case DictionaryIncompatible(elementType: Any.Type)
    case PropertyIncompatibleType(key: String, elementType: Any.Type)

    func toNSError() -> NSError {
        let domain = "ai.wit.json.encodingError"
        switch self {
        case .ArrayIncompatible(let elementType):
            return NSError(domain: domain, code: 1, userInfo: ["elementType": String(elementType)])
        case .DictionaryIncompatible(let elementType):
            return NSError(domain: domain, code: 2, userInfo: ["elementType": String(elementType)])
        case .PropertyIncompatibleType(let key, let elementType):
            return NSError(domain: domain, code: 3, userInfo: ["key": key, "elementType": String(elementType)])
        }
    }
}

public protocol JSONConvertable {
    func toJSON() throws -> AnyObject
}

internal protocol JSONArray {
    func elementIsJSONConvertable() -> Bool
    func elementToJSONConvertable() -> [JSONConvertable]
}

extension Array : JSONArray {
    public var wrapped : [JSONConvertable] {
        return elementToJSONConvertable()
    }

    func elementIsJSONConvertable() -> Bool {
        return Element.self is JSONConvertable.Type || Element.self is JSONConvertable.Protocol
    }

    func elementToJSONConvertable() -> [JSONConvertable] {
        return self.map{$0 as! JSONConvertable}
    }
}

extension Array {
    func toJSON() throws -> [AnyObject] {
        guard elementIsJSONConvertable() else {
            throw JSONEncodingError.ArrayIncompatible(elementType: Element.self)
        }
        var arr = [AnyObject]()
        for item in wrapped {
            arr.append(try item.toJSON())
        }
        return arr
    }
}

internal protocol JSONDictionary {
    func elementIsJSONConvertable() -> Bool
    func elementToJSONConvertable() -> [String: JSONConvertable]
}

extension Dictionary : JSONDictionary {

    func elementIsJSONConvertable() -> Bool {
        return Key.self is String.Type && (Value.self is JSONConvertable.Type || Value.self is JSONConvertable.Protocol)
    }

    func elementToJSONConvertable() -> [String : JSONConvertable] {
        var result: [String : JSONConvertable] = [:]
        for (key, value) in self {
            result[String(key)] = value as? JSONConvertable
        }
        return result
    }
}

extension Dictionary {
    func toJSON() throws -> AnyObject {
        guard elementIsJSONConvertable() else {
            throw JSONEncodingError.DictionaryIncompatible(elementType: Value.self)
        }
        let unwrapped = elementToJSONConvertable()
        var result:[String : AnyObject] = [:]
        for (key, value) in unwrapped {
            result[key] = try value.toJSON()
        }
        return result
    }
}

public protocol JSONPrimaryType : JSONConvertable {}
public extension JSONPrimaryType {
    func toJSON() throws -> AnyObject {
        return self as! AnyObject
    }
}

internal protocol JSONOptional {
    var unwrapped: Any? {get}
}

extension Optional : JSONOptional {
    var unwrapped : Any? {
        return self
    }
}

extension String:JSONPrimaryType {}
extension Int: JSONPrimaryType {}
extension Float: JSONPrimaryType {}
extension Double : JSONPrimaryType {}
extension Bool : JSONPrimaryType {}

public protocol JSONTransformable: JSONConvertable {
    associatedtype EncodeType
    associatedtype DecodeType
    static func fromJSON(json: EncodeType) throws -> DecodeType?
}

extension NSDate : JSONTransformable {
    public func toJSON() throws -> AnyObject {
        return dateTransformer.encode(self)
    }

    public static func fromJSON(json: String) throws -> NSDate? {
        guard let date = dateTransformer.decode(json) else {
            throw JSONDecodingError.ValueNotTransformable(value: json)
        }
        return date
    }
}

extension NSURL : JSONTransformable {
    public func toJSON() throws -> AnyObject {
        return urlTransformer.encode(self)
    }

    public static func fromJSON(json: String) throws -> NSURL? {
        guard let url = urlTransformer.decode(json) else {
            throw JSONDecodingError.ValueNotTransformable(value: json)
        }
        return url
    }
}

public extension JSONConvertable {
    func toJSON() throws -> AnyObject {
        var dic = [String: AnyObject]()
        let mirror = Mirror(reflecting: self)
        for (keyMaybe, valueMaybe) in mirror.children {
            guard let key = keyMaybe else {
                continue
            }
            var theValue = valueMaybe
            if let val = valueMaybe as? JSONOptional {
                guard let notNilValue = val.unwrapped else {
                    continue
                }
                theValue = notNilValue
            }
            switch theValue {
            case let value as JSONConvertable:
                dic[key] = try value.toJSON()
            case let value as JSONArray:
                dic[key] = try value.elementToJSONConvertable().toJSON()
            case let value as JSONDictionary:
                dic[key] = try value.elementToJSONConvertable().toJSON()
            default:
                throw JSONEncodingError.PropertyIncompatibleType(key: key, elementType: valueMaybe.dynamicType)
            }
        }
        return dic
    }
}