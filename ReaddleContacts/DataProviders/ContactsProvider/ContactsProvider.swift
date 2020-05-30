//
//  ContactsProvider.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import PromiseKit

/// Plain data struct for contacts
public struct Contact {
    public init(firstName: String, lastName: String? = nil, email: String? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }

    public let firstName: String
    public let lastName: String?
    public let email: String?
    
    public var fullName: String {
        var res = firstName
        if let l = lastName {
            res = [res, l].joined(separator: " ")
        }
        return res
    }
}

// Error
public enum ContactsProviderError: Error {
    case noSuchContact(id: ContactID)
    case unknown(_ description: String)
}

extension ContactsProviderError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .unknown(let description): return "Unknown: \(description)"
        case .noSuchContact(let id): return "No such id: \(id)"
        }
    }
}

// Typealiases
public typealias Contacts = [ContactID: Contact]
public typealias ContactID = Int

/// Provides contacts data methods for async queries
public protocol ContactsProvider {
    // Read queries
    var contactsCount: Int { get }

    /// Gets all contacts
    func getAllContacts() -> Promise<Contacts>

    /// Gets contact by ID, returns error if no such contact
    /// - Parameters:
    ///   - id: Contact ID
    func getContact(id: ContactID) -> Promise<Contact>

    /// Gets online status of contact, returns error if no such contact
    /// - Parameters:
    ///   - id: Contact ID
    func isOnline(id: ContactID) -> Promise<Bool>

    // Modify queries

    /// Adds contact and return added contact ID
    /// - Parameters:
    ///   - contact: Contact object to add
    func addContact(_ contact: Contact) -> Promise<ContactID>

    /// Removes contact with specified ID, returns error if no such contact
    /// - Parameters:
    ///   - id: Contact ID to remove
    func removeContact(id: ContactID) -> Promise<Contact>

    func updateOnline() -> Promise<Void>
}
