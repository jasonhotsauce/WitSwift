//: Playground - noun: a place where people can play
import WitSwift
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

struct Configuration : Configurable {
    var token: String {
        return "LZNTCJ5PNBZNE2WLNBUB7EJLZMN2CDM5"
    }

    var version: String {
        return "20160516"
    }
}

let config = Configuration()
let query = "hello"

converseHandler = { converse in
    switch converse.type {
    case .Merge:
        if let entities = converse.entities {
            print(entities)
        }
        return nil

    case .Action:
        print(converse.action)
        return nil

    case .Message:
        print(converse.msg)
        return nil

    case .Stop:
        return nil
    }
}

let sessionID = NSUUID().uuidString
getConverse(config, query: query, sessionID: sessionID, maxStep: 5) { (error) in
    print(error)
}
