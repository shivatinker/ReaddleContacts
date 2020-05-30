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
    private var online = [ContactID: Bool]()
    private var nextID = 0

    private func callbackBackground<T>(_ f: @escaping ContactsProviderCallback<T>, _ r: ContactsResult<T>) {
        queue.async {
            f(r)
        }
    }
}

extension MockContactsProvider: ContactsProvider {
    public func updateOnline(callback: @escaping ContactsProviderCallback<Void>) {
        for id in contacts.map({ id, _ in id }) {
            online[id] = Bool.random()
        }
        callbackBackground(callback, .success(result: ()))
    }

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
            callbackBackground(callback, .success(result: self.online[id] ?? false))
        }
    }

    public func addContact(_ contact: Contact, callback: @escaping ContactsProviderCallback<ContactID>) {
        contacts[nextID] = contact
        online[nextID] = Bool.random()
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
