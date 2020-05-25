//
//  ContactProviderTests.swift
//  ReaddleContactsTests
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import XCTest
@testable import ReaddleContacts

class ContactProviderTests: XCTestCase {

    func testGetContact(_ p: ContactsProvider, id: ContactID) -> Contact {
        let e = expectation(description: "Getting contact")
        var cr: Contact!
        p.getContact(id: id) { (res) in
            switch res {
            case .failure(let error): XCTFail(error.localizedDescription)
            case .success(let result):
                cr = result
                e.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
        return cr
    }

    func testGetWrongContact(_ p: ContactsProvider, id: ContactID) {
        let e = expectation(description: "Getting contact")
        p.getContact(id: id) { (res) in
            switch res {
            case .failure(let error):
                switch error {
                case .noSuchContact(let nid):
                    XCTAssertEqual(nid, id)
                    e.fulfill()
                default:
                    XCTFail("Wrong error type")
                }
            case .success(let result):
                XCTFail("Contact \(result) should had been deleted!")
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testAddContact(_ p: ContactsProvider, _ c: Contact) -> ContactID {
        let e = expectation(description: "Adding contact")
        let preCount = p.contactsCount
        var cid: Int!
        p.addContact(c) { (res) in
            switch res {
            case .failure(let error): XCTFail(error.localizedDescription)
            case .success(let result):
                cid = result
                e.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(p.contactsCount, preCount + 1)

        let added = testGetContact(p, id: cid)
        XCTAssertEqual(added.fullName, c.fullName)

        return cid
    }

    func testRemoveContact(_ p: ContactsProvider, _ id: ContactID) {
        let toberemoved = testGetContact(p, id: id)

        let e = expectation(description: "Removing contact")
        let preCount = p.contactsCount

        var removed: Contact!
        p.removeContact(id: id) { (res) in
            switch res {
            case .failure(let error): XCTFail(error.localizedDescription)
            case .success(let result):
                removed = result
                e.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(p.contactsCount, preCount - 1)

        testGetWrongContact(p, id: id)
        XCTAssertEqual(removed.fullName, toberemoved.fullName)
    }

    func testGetAllContacts(_ p: ContactsProvider) -> Contacts {
        let e = expectation(description: "Getting all contacts")
        var cr: Contacts!
        p.getAllContacts() { (res) in
            switch res {
            case .failure(let error): XCTFail(error.localizedDescription)
            case .success(let result):
                cr = result
                e.fulfill()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
        return cr
    }

    func testContactProvider(_ p: ContactsProvider) {
        let id = testAddContact(p, Contact(firstName: "Abc", lastName: "Bbc"))
        testRemoveContact(p, id)
    }

    func testMock() {
        let testContact: Contact = Contact(firstName: "Andrii", lastName: "Zinoviev")
        let p = MockContactsProvider(contacts: [testContact])

        let all = testGetAllContacts(p)
        XCTAssert(all.values.first(where: { $0.fullName == testContact.fullName }) != nil)
        XCTAssertEqual(p.contactsCount, 1)

        testContactProvider(p)
    }

    func testContactStruct() {
        let c1 = Contact(firstName: "Andrii", lastName: "Zinoviev")
        let c2 = Contact(firstName: "Andrii")

        XCTAssertEqual(c1.fullName, "Andrii Zinoviev")
        XCTAssertEqual(c2.fullName, "Andrii")
    }

}
