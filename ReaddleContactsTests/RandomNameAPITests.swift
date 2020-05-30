//
//  RandomNameAPITests.swift
//  ReaddleContactsTests
//
//  Created by Andrii Zinoviev on 30.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import XCTest
@testable import ReaddleContacts

class RandomNameAPITests: XCTestCase {

    let api = RandomNameAPI()
    func testRandomNameAPI() {
        let e = expectation(description: "")
        api.getRandomNames(count: 150).done { names in
            XCTAssert(names.count == 150)
            debugPrint(names)
            e.fulfill()
        }.catch {
            XCTFail($0.localizedDescription)
        }
        waitForExpectations(timeout: 5.0)
    }
}
