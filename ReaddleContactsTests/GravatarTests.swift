//
//  ReaddleContactsTests.swift
//  ReaddleContactsTests
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import XCTest
@testable import ReaddleContacts

class GravatarTests: XCTestCase {

    private let gravatarAPI: GravatarAPI = NetGravatarAPI()

    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws {
    }

    func testMD5() throws {
        let s = "asdkfmepqmfieqpfds"
        let d = s.md5()
        XCTAssertEqual("fbe26536e3988bc3894e407bc96ea94b", d)
    }

    func testGetAvatar(_ email: String, params: GravatarParams, timeout: TimeInterval = 3) {
        let e = expectation(description: "Test gravatar")

        gravatarAPI.getAvatarImage(email: email, params: params).done { image in
            e.fulfill()
        }.catch {
            XCTFail($0.localizedDescription)
        }

        waitForExpectations(timeout: timeout) { (error) in
            if let error = error {
                XCTFail("\(error)")
            }
        }
    }

    func testGravatarAvatars() {
        let goodEmail = "zinoviev@stud.onu.edu.ua"
        testGetAvatar(goodEmail, params: GravatarParams(taskId: 0, size: 100))
        testGetAvatar(goodEmail, params: GravatarParams(taskId: 0, size: 200))
        testGetAvatar(goodEmail, params: GravatarParams(taskId: 0, size: 40))
        let goodEmail2 = "lytvynenko@stud.onu.edu.ua"
        testGetAvatar(goodEmail2, params: GravatarParams(taskId: 0, size: 200))
        let badEmail = "d.d.-r1l-d9kd"
        testGetAvatar(badEmail, params: GravatarParams(taskId: 0, size: 100))
        testGetAvatar(badEmail, params: GravatarParams(taskId: 0, size: 200))
        testGetAvatar(badEmail, params: GravatarParams(taskId: 0, size: 40))
    }
}
