//
//  ErrorConvertable.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 7/3/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import Foundation

protocol ErrorConvertable {
    func toNSError() -> NSError;
}

extension NSError : ErrorConvertable {
    func toNSError() -> NSError {
        return self;
    }
}
