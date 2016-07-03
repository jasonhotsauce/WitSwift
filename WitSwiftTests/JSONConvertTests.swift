//
//  JSONConvertTests.swift
//  WitSwift
//
//  Created by Wenbin Zhang on 5/1/16.
//  Copyright © 2016 Wenbin Zhang. All rights reserved.
//

import XCTest
@testable import WitSwift

struct TestParent : JSONConvertable, JSONDecodable {
    var age: Int
    var name: String
    var children: [TestChild]
    var phones: [String: String]
    var birthday: Date
    var profilePage: URL

    init(age: Int, name: String, children:[TestChild], phones: [String: String], birthday: Date, profilePage: URL) {
        self.age = age;
        self.name = name;
        self.children = children
        self.phones = phones
        self.birthday = birthday
        self.profilePage = profilePage
    }

    init(json: JSON) throws {
        let decoder = JSONDecoder(json: json)
        age = try decoder.decode("age")
        name = try decoder.decode("name")
        children = try decoder.decode("children")
        phones = try decoder.decode("phones")
        birthday = try decoder.decode("birthday", transformer: dateTransformer)
        profilePage = try decoder.decode("profilePage", transformer: urlTransformer)
    }
}

struct TestChild : JSONConvertable, JSONDecodable {
    var childName: String
    var childAge: Int
    var birthday: Date

    init(childName: String, childAge: Int, birthday: Date) {
        self.childName = childName
        self.childAge = childAge
        self.birthday = birthday
    }

    init(json: JSON) throws {
        let decoder = JSONDecoder(json: json)
        childName = try decoder.decode("childName")
        childAge = try decoder.decode("childAge")
        birthday = try decoder.decode("birthday", transformer: dateTransformer)
    }
}

extension TestChild : Equatable {}
func ==(l: TestChild, r: TestChild) -> Bool {
    return l.childAge == r.childAge && l.childName == r.childName && (l.birthday == r.birthday)
}

class JSONConvertTests: XCTestCase {

    var parent: TestParent!

    override func setUp() {
        super.setUp()
        let child1 = TestChild(childName: "John", childAge: 10, birthday: Date(timeIntervalSince1970: 1146582302))
        let child2 = TestChild(childName: "Joey", childAge: 11, birthday: Date(timeIntervalSince1970: 1115046302))
        parent = TestParent(age: 35, name: "Mason", children: [child1, child2], phones: ["home":"1233211234", "mobile": "4155678901"], birthday: Date(timeIntervalSince1970: 357663902), profilePage: URL(string: "http://test.com")!)
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testConvertToJSON() {
        let json = try! parent.toJSON() as! [String: AnyObject]
        XCTAssertNotNil(json["age"])
        XCTAssertEqual(json["age"] as? Int, 35)
        XCTAssertEqual(json["name"] as? String, "Mason")
        let children = json["children"] as? [[String: AnyObject]]
        XCTAssertEqual(children?.count, 2)
        let child1 = children?[0]
        XCTAssertEqual(child1?["childName"] as? String, "John")
        XCTAssertEqual(child1?["childAge"] as? Int, 10)
        XCTAssertEqual(child1?["birthday"] as? String, "2006-05-02T08:05:02-07:00")
        XCTAssertEqual((json["phones"] as? [String: String])!, ["home":"1233211234", "mobile": "4155678901"])
        XCTAssertEqual(json["birthday"] as? String, "1981-05-02T08:05:02-07:00")
        XCTAssertEqual(json["profilePage"] as? String, "http://test.com")
    }

    func testFromJSON() {
        let json = ["age": 35, "name": "Mason","phones": ["home":"1233211234", "mobile": "4155678901"], "birthday": "1981-05-02T08:05:02-07:00", "profilePage": "http://test.com", "children":[["childName": "John", "childAge": 10, "birthday": "2006-05-02T08:05:02-07:00"], ["childName": "Joey", "childAge": 11, "birthday": "2005-05-02T08:05:02-07:00"]]]
        let parent = try! TestParent(json: json)
        XCTAssertNotNil(parent)
        XCTAssertEqual(parent.name, "Mason")
        XCTAssertEqual(parent.age, 35)
        XCTAssertEqual(parent.children.count, 2)
        let child = parent.children.first!
        let expected = TestChild(childName: "John", childAge: 10, birthday: Date(timeIntervalSince1970: 1146582302))
        XCTAssertEqual(child, expected)
    }

}
