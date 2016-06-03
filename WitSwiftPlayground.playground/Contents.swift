//: Playground - noun: a place where people can play
import WitSwift
import XCPlayground
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

struct Configuration : Configurable {
    var token: String {
        return "{Your token here}"
    }

    var version: String {
        return "20160516"
    }
}

let config = Configuration()
let query = "What's the weather today"
getIntent(config, query: query, messageID: nil, threadID: nil) { (success, message, error) in
    if !success {
        print(error)
    } else {
        print(message)
    }
}