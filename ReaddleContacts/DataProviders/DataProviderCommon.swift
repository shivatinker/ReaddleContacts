//
//  DataProviderCommon.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import PromiseKit

public protocol ErrorHandler {
    func error(_ e: Error)
}

public struct DataContext {
    public let contact: ContactsProvider
    public let gravatar: GravatarAPI
    public let randomInfo: RandomNameAPI

    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    /// Gets contact info and online status
    /// - Parameter id: contact id
    /// - Returns: Promise
    public func getContactInfoAndOnline(for id: ContactID) -> Promise<(Contact, Bool)> {
        return when(fulfilled: self.contact.getContact(id: id),
                    self.contact.isOnline(id: id))
    }
    
    /// Simulates changes, adds and removes `amount` new random contacts, updates online statuses
    /// - Parameter amount: number of contacts to be added and removed
    /// - Returns: Promise
    public func simulateChanges(amount: Int = 30) -> Promise<Void> {
        firstly {
            self.contact.getAllContacts()
        }.map { contacts in
            return Array(contacts.map({ (id, _) in id }).shuffled().prefix(amount))
        }.then { ids in
            when(fulfilled: ids.map { id in
                self.contact.removeContact(id: id)
            }).asVoid()
        }.then { _ in
            self.addRandomContacts(count: amount)
        }.then {
            self.contact.updateOnline()
        }
    }
    
    /// Loads avatar for specified contact `id`
    /// - Parameters:
    ///   - id: Contact id
    ///   - size: Requested avatar size
    /// - Returns: Promise
    public func getAvatar(for id: ContactID, size: Int) -> Promise<UIImage?> {
        let params = GravatarParams(taskId: id, size: size, defaultAvatar: .identicon)
        return firstly {
            self.contact.getContact(id: id)
        }.then { (contact: Contact) -> Promise<UIImage?> in
            if let email = contact.email {
                return self.gravatar.getAvatarImage(email: email, params: params)
            } else {
                return Promise<UIImage?> { seal in
                    seal.fulfill(nil)
                }
            }
        }
    }
    
    /// Adds `count` random contacts
    /// - Parameter count: Number of contacts to be added
    /// - Returns: Promise
    public func addRandomContacts(count: Int) -> Promise<Void> {
        randomInfo.getRandomNames(count: count).map { infos in
            infos.map({ Contact(firstName: $0.firstName,
                                lastName: $0.lastName,
                                email: $0.email) })
        }.then { contacts in
            when(fulfilled: contacts.map { contact in
                self.contact.addContact(contact).asVoid()
            })
        }
    }
}
