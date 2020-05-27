//
//  AllContactsPresener.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import UIKit

public struct ContactViewData {
    public let id: Int
    public let fullName: String
    public let email: String?
    public let online: Bool
}

public struct AllContactsViewData {
    public let contacts: [ContactViewData]
}

public protocol AllContactsView: AnyObject {
    func setData(_ data: AllContactsViewData)
    func startLoading()
    func stopLoading()
}

public class AllContactsPresenter {
    // MARK: Private members
    private static let MAX_LOADINGS_ALLOWED = 10

    private let context: DataContext
    private weak var view: AllContactsView?
    private let errorHandler: ErrorHandler?

    // MARK: Public API

    public init(context: DataContext, view: AllContactsView, errorHandler: ErrorHandler? = nil) {
        self.context = context
        self.view = view
        self.errorHandler = errorHandler
    }

    public func loadAvatar(for id: Int, size: Int, callback: @escaping (UIImage?) -> ()) {
        context.contact.getContact(id: id) { (res) in
            if let contact = res.unwrap(errorHandler: self.errorHandler),
                let email = contact.email {
                let request = GravatarRequest(email: email, size: size)
                self.context.gravatar.getAvatarImage(request) { (res) in
                    callback(res.unwrap(errorHandler: self.errorHandler))
                }
            } else {
                callback(nil)
            }
        }
    }

    // TODO: Parallel load
    public func loadContact(id: Int, callback: @escaping (ContactViewData?) -> ()) {
        context.contact.getContact(id: id) { (res) in
            if let contact = res.unwrap(errorHandler: self.errorHandler) {
                self.context.contact.isOnline(id: id) { (res) in
                    callback(ContactViewData(
                        id: id,
                        fullName: contact.fullName,
                        email: contact.email,
                        online: res.unwrap(errorHandler: self.errorHandler) ?? false))
                }
            } else {
                callback(nil)
            }
        }
    }

    public func loadContactIDs(callback: @escaping ([Int]?) -> ()) {
        context.contact.getAllContacts { (res) in
            if let contacts = res.unwrap(errorHandler: self.errorHandler) {
                callback(contacts.sorted(by: { (e1, e2) -> Bool in
                    e1.1.fullName < e2.1.fullName
                }).map({ $0.0 }))
            } else {
                callback(nil)
            }
        }
    }

    public func update() {

    }
}
