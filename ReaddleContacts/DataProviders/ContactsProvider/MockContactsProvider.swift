//
//  MockContactsProvider.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import PromiseKit

public class MockContactsProvider {

    private var queue = DispatchQueue(label: "com.shivatinker.contacts.contactsProvider", qos: .userInitiated)
    private var contacts = Contacts()
    private var online = [ContactID: Bool]()
    private var nextID = 0

}

extension MockContactsProvider: ContactsProvider {
    public var contactsCount: Int {
        contacts.count
    }

    public func getAllContacts() -> Promise<Contacts> {
        Promise { seal in
            queue.async {
                seal.fulfill(self.contacts)
            }
        }
    }

    public func getContact(id: ContactID) -> Promise<Contact> {
        Promise { seal in
            queue.async {
                guard let c = self.contacts[id] else {
                    seal.reject(ContactsProviderError.noSuchContact(id: id))
                    return
                }
                seal.fulfill(c)
            }
        }
    }

    public func isOnline(id: ContactID) -> Promise<Bool> {
        Promise { seal in
            queue.async {
                if self.contacts[id] == nil {
                    seal.reject(ContactsProviderError.noSuchContact(id: id))
                } else {
                    seal.fulfill(self.online[id] ?? false)
                }
            }
        }
    }

    public func addContact(_ contact: Contact) -> Promise<ContactID> {
        Guarantee<ContactID> { seal in
            queue.async {
                self.contacts[self.nextID] = contact
                self.online[self.nextID] = Bool.random()
                seal(self.nextID)
            }
        }.get(on: queue) { _ in
            self.nextID += 1
        }
    }

    public func removeContact(id: ContactID) -> Promise<Contact> {
        Promise { seal in
            queue.async {
                guard let c = self.contacts[id] else {
                    seal.reject(ContactsProviderError.noSuchContact(id: id))
                    return
                }
                self.contacts[id] = nil
                seal.fulfill(c)
            }
        }
    }

    public func updateOnline() -> Promise<Void> {
        Promise { seal in
            queue.async {
                for id in self.contacts.map({ id, _ in id }) {
                    self.online[id] = Bool.random()
                }
                seal.fulfill(())
            }
        }
    }
}
