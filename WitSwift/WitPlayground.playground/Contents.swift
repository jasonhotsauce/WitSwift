//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"

enum TestError : ErrorType {
    case Test
}

func testThrow() throws {
    throw TestError.Test
}

do {
    try testThrow()
} catch let error as TestError {
    print("test error")
}