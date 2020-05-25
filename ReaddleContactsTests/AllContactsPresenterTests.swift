//
//  AllContactsPresenterTests.swift
//  ReaddleContactsTests
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import XCTest
@testable import ReaddleContacts

private class TestErrorHandler: ErrorHandler {
    func error(_ e: Error) {
        print("[Error]: \(e)")
    }
}

private class TestView: AllContactsView {
    public var presenter: AllContactsPresenter?
    private let expectation: XCTestExpectation

    internal var contacts: AllContactsViewData?
    internal var avatars = [Int: UIImage]()
    internal var statusChanged = [Int: Bool]()

    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    func startLoading() {
        print("Start loading")
    }

    func stopLoading() {
        print("Stop loading")
        expectation.fulfill()
    }

    func setData(_ data: AllContactsViewData) {
        contacts = data
//        data.contacts.forEach({
//            print("\($0.id) - \($0.fullName) - \($0.email ?? "No email")")
//        })
    }

    func setAvatar(id: Int, _ avatar: UIImage) {
//        print("Avatar set for \(id)")
        avatars[id] = avatar
    }

    func setOnline(id: Int, _ online: Bool) {
//        print("\(id) went \(online ? "online" : "offline")")
        statusChanged[id] = true
    }
}

class AllContactsPresenterTests: XCTestCase {

    private var view: TestView!

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
        view.presenter = AllContactsPresenter(
            context: DataContext(contact: contacts, gravatar: gravatar),
            view: view,
            errorHandler: TestErrorHandler())
    }

    func testPresenter() {
        view.presenter?.update()
        waitForExpectations(timeout: 5, handler: nil)

        if let data = view.contacts {
            XCTAssert(data.contacts.allSatisfy({ self.view.avatars[$0.id] != nil }))
            XCTAssert(data.contacts.allSatisfy({ self.view.statusChanged[$0.id] ?? false }))
        } else {
            XCTFail("No contacts loaded")
        }
    }

}
