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
        let d = NetGravatarAPI.MD5(messageData: s.data(using: .utf8)!)
        XCTAssertEqual("fbe26536e3988bc3894e407bc96ea94b", d)
    }

    func testGetAvatar(_ request: GravatarRequest, timeout: TimeInterval = 3) {
        let e = expectation(description: "Test gravatar")

        gravatarAPI.getAvatarImage(request) { res in
            switch res {
            case .failure(let error): XCTFail(error.localizedDescription)
            case .success(let image):
                XCTAssertEqual(request.size, Int(image.size.width * image.scale))
                XCTAssertEqual(request.size, Int(image.size.height * image.scale))
            }
            e.fulfill()
        }
        waitForExpectations(timeout: timeout) { (error) in
            if let error = error {
                XCTFail("\(error)")
            }
        }
    }

    func testGravatarAvatars() {
        let goodEmail = "zinoviev@stud.onu.edu.ua"
        testGetAvatar(GravatarRequest(email: goodEmail, size: 100))
        testGetAvatar(GravatarRequest(email: goodEmail, size: 200))
        testGetAvatar(GravatarRequest(email: goodEmail, size: 40))
        let goodEmail2 = "lytvynenko@stud.onu.edu.ua"
        testGetAvatar(GravatarRequest(email: goodEmail2, size: 200))
        let badEmail = "d.d.-r1l-d9kd"
        testGetAvatar(GravatarRequest(email: badEmail, size: 100))
        testGetAvatar(GravatarRequest(email: badEmail, size: 200))
        testGetAvatar(GravatarRequest(email: badEmail, size: 40))
    }
}
