//
//  Configuration.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 4/25/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation

public protocol Configurable {
    var token: String {get}
    var version: String {get}
}