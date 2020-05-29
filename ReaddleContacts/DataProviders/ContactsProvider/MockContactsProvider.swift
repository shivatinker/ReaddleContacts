//
//  MockContactsProvider.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation

public class MockContactsProvider {

    private var queue = DispatchQueue(label: "Contacts provider", qos: .userInitiated)
    private var contacts = Contacts()
    private var nextID = 0

    public convenience init() {
        var c: [Contact] = [
            Contact(firstName: "Andrii", email: "zinoviev@stud.onu.edu.ua")
        ]

        for i in 0...1000 {
            c.append(Contact(firstName: "Stranger", email: "\(i)@gmail.com"))
        }

        c.append(Contact(firstName: "A very long name, very long, literally"))

        self.init(contacts: c)
    }

    public convenience init(randomCount: Int) {
        var c = [Contact]()
        for i in 0..<randomCount {
            c.append(Contact(firstName: "Stranger", email: "\(i)@gmail.com"))
        }
        self.init(contacts: c)
    }

    public init(contacts: [Contact]) {
        contacts.forEach({
            self.contacts[nextID] = $0
            nextID += 1
        })
    }

    private func callbackBackground<T>(_ f: @escaping ContactsProviderCallback<T>, _ r: ContactsResult<T>) {
        queue.async {
            f(r)
        }
    }
}

extension MockContactsProvider: ContactsProvider {
    public var contactsCount: Int {
        contacts.count
    }

    public func getAllContacts(callback: @escaping ContactsProviderCallback<Contacts>) {
        callbackBackground(callback, .success(result: contacts))
    }

    public func getContact(id: ContactID, callback: @escaping ContactsProviderCallback<Contact>) {
        guard let c = contacts[id] else {
            callbackBackground(callback, .failure(error: .noSuchContact(id: id)))
            return
        }
        callbackBackground(callback, .success(result: c))
    }

    public func isOnline(id: ContactID, callback: @escaping ContactsProviderCallback<Bool>) {
        if contacts[id] == nil {
            callbackBackground(callback, .failure(error: .noSuchContact(id: id)))
        } else {
            callbackBackground(callback, .success(result: Bool.random()))
        }
    }

    public func addContact(_ contact: Contact, callback: @escaping ContactsProviderCallback<ContactID>) {
        contacts[nextID] = contact
        callbackBackground(callback, .success(result: nextID))
        nextID += 1
    }

    public func removeContact(id: ContactID, callback: @escaping ContactsProviderCallback<Contact>) {
        guard let c = contacts[id] else {
            callbackBackground(callback, .failure(error: .noSuchContact(id: id)))
            return
        }
        contacts[id] = nil
        callbackBackground(callback, .success(result: c))
    }
}
