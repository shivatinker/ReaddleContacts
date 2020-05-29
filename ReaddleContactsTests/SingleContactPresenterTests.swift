//
//  SingleContactPresenterTests.swift
//  ReaddleContactsTests
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import XCTest
@testable import ReaddleContacts

// TODO: Merge presenter tests (maybe)
private class TestErrorHandler: ErrorHandler {
    func error(_ e: Error) {
        print("[Error]: \(e)")
    }
}

private class TestView: SingleContactPresenterDelegate {
    private let expectation: XCTestExpectation

    internal var data: SingleContactViewData?
    internal var onlineChanged: Bool = false
    internal var avatar: UIImage?

    internal init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    func setData(_ data: SingleContactViewData) {
        self.data = data
    }

    func setOnline(_ online: Bool) {
        onlineChanged = true
    }

    func setAvatar(_ avatar: UIImage) {
        self.avatar = avatar
    }

    func startLoading() {
        print("Start loading")
    }

    func stopLoading() {
        print("Stop loading")
        expectation.fulfill()
    }
}

class SingleContactPresenterTests: XCTestCase {

    private var view: TestView!
    private var presenter: SingleContactPresenter!

    private let cont: [Contact] = [
        Contact(firstName: "Andrii", email: "zinoviev@stud.onu.edu.ua"),
        Contact(firstName: "Inna", email: "lytvynenko@stud.onu.edu.ua"),
        Contact(firstName: "Stranger", email: "1134ocg@stud.onu.edu.ua"),
        Contact(firstName: "Andrii", email: "zinoviev@stud.onu.edu.ua"),
        Contact(firstName: "Inna", email: "lytvynenko@stud.onu.edu.ua"),
        Contact(firstName: "Stranger", email: "1134ocg@stud.onu.edu.ua"),
        Contact(firstName: "Andrii", email: "zinoviev@stud.onu.edu.ua"),
        Contact(firstName: "Inna", email: "lytvynenko@stud.onu.edu.ua"),
        Contact(firstName: "Stranger", email: "1134ocg@stud.onu.edu.ua"),
        Contact(firstName: "Andrii", email: "zinoviev@stud.onu.edu.ua"),
        Contact(firstName: "Inna", email: "lytvynenko@stud.onu.edu.ua"),
        Contact(firstName: "Stranger", email: "1134ocg@stud.onu.edu.ua"),
    ]

    override func setUp() {
        let contacts = MockContactsProvider(contacts: cont)
        let gravatar = NetGravatarAPI()

        view = TestView(expectation: expectation(description: "Load contacts"))
        presenter = SingleContactPresenter(
            context: DataContext(contact: contacts, gravatar: gravatar),
            view: view,
            errorHandler: TestErrorHandler())
    }

    func testPresenter() {
        presenter.update(id: 6)
        waitForExpectations(timeout: 5, handler: nil)

        XCTAssert(view.data != nil)
        XCTAssert(view.avatar != nil)
        XCTAssert(view.onlineChanged)
    }

}
