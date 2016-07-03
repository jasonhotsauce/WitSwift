//
//  Context.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 4/26/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation

public protocol LocationLike : JSONConvertable {
    var latitude: Double {get}
    var longitude: Double {get}
}

public protocol EntityLike : JSONConvertable {
    var id : String {get}
    var expressions : [String] {get}
}

public protocol Contextable : JSONConvertable {
    var state : [String]? {get}
    var referenceTime : Date? {get}
    var timezone: String? {get}
    var location: LocationLike? {get}
    var entities: [EntityLike]? {get set}
}

internal struct Context: Contextable {

    var state: [String]? {
        return nil
    }

    var referenceTime: Date? {
        return Date()
    }

    var timezone: String? {
        return TimeZone.local().name
    }

    var location: LocationLike? {
        return nil
    }

    var entities: [EntityLike]?
}
