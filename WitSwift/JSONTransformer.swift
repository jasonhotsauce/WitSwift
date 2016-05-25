//
//  JSONTransformer.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 5/5/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation

public struct JSONTransformer<EncodeType, DecodeType> {
    var encode: DecodeType -> EncodeType
    var decode: EncodeType -> DecodeType?
}

private let dateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    return formatter
}()

internal let dateTransformer = JSONTransformer(encode: { (date: NSDate) -> String in
    return dateFormatter.stringFromDate(date)
}) { (dateStr: String) -> NSDate? in
        return dateFormatter.dateFromString(dateStr)
}

internal let urlTransformer = JSONTransformer<String, NSURL>(encode: {$0.absoluteString}, decode: {NSURL(string: $0)})