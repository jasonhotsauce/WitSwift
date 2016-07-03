//
//  JSONTransformer.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 5/5/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation

public struct JSONTransformer<EncodeType, DecodeType> {
    var encode: (DecodeType) -> EncodeType
    var decode: (EncodeType) -> DecodeType?
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    return formatter
}()

internal let dateTransformer = JSONTransformer(encode: { (date: Date) -> String in
    return dateFormatter.string(from: date)
}) { (dateStr: String) -> Date? in
        return dateFormatter.date(from: dateStr)
}

internal let urlTransformer = JSONTransformer<String, URL>(encode: {$0.absoluteString!}, decode: {URL(string: $0)})
