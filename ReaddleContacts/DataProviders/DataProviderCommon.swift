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

public enum ConditionalResult<T, E: Error> {
    case success(result: T)
    case failure(error: E)

    /// Unwraps result
    /// If result is success returns unwrapped result object
    /// If result is failure passes an error to errorHandler and returns nil
    /// - Parameter errorHandler: ErrorHandler to handle failure case
    /// - Returns: Optional T value
    public func unwrap(errorHandler: ErrorHandler? = nil) -> T? {
        switch self {
        case .failure(let error): errorHandler?.error(error)
        case .success(let result): return result
        }
        return nil
    }
}

public struct DataContext {
    public let contact: ContactsProvider
    public let gravatar: GravatarAPI

    private func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    public func simulateChanges() -> Promise<Void> {
        firstly {
            getAllContactP()
        }.map { contacts in
            return Array(contacts.map({ (id, _) in id }).shuffled().prefix(30))
        }.then { ids in
            when(fulfilled: ids.map { id in
                self.removeContactP(id: id)
            }).asVoid()
        }.then { _ -> Promise<Void> in
            var toAdd = [Contact]()
            for _ in 0..<30 {
                toAdd.append(Contact(firstName: self.randomString(length: 8),
                                     lastName: self.randomString(length: 6),
                                     email: self.randomString(length: 10).appending("@gmail.com")))
            }
            let pr = toAdd.map { contact in
                self.addContactP(contact)
            }
            return when(fulfilled: pr).asVoid()
        }
    }
}
