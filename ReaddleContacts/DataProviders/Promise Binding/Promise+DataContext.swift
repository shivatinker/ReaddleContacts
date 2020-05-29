//
//  Promise+DataContext.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 29.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import PromiseKit

public extension DataContext {
    private func applyResult<T, E: Error>(_ result: ConditionalResult<T, E>, _ seal: Resolver<T>) {
        switch result {
        case .failure(let error): seal.reject(error)
        case .success(let result): seal.fulfill(result)
        }
    }

    func getContactInfoP(for id: ContactID) -> Promise<Contact> {
        return Promise { seal in
            contact.getContact(id: id) { (res) in
                self.applyResult(res, seal)
            }
        }
    }

    func getAllContactP() -> Promise<Contacts> {
        return Promise { seal in
            contact.getAllContacts { (res) in
                self.applyResult(res, seal)
            }
        }
    }

    func isOnlineP(id: ContactID) -> Promise<Bool> {
        return Promise { seal in
            contact.isOnline(id: id) { (res) in
                self.applyResult(res, seal)
            }
        }
    }

    func getContactInfoAndOnlineP(for id: ContactID) -> Promise<(Contact, Bool)> {
        return when(fulfilled: getContactInfoP(for: id), isOnlineP(id: id))
    }

    func getAvatarP(for id: ContactID) -> Promise<UIImage?> {
        return firstly {
            getContactInfoP(for: id)
        }.then { contact in
            Promise { seal in
                if let email = contact.email {
                    self.gravatar.getAvatarImage(GravatarRequest(email: email, taskId: id)) { (res) in
                        self.applyResult(res, seal)
                    }
                } else {
                    seal.fulfill(nil)
                }
            }
        }
    }
}
