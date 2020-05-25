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
}

public struct AllContactsViewData {
    public let contacts: [ContactViewData]
}

public protocol AllContactsView: AnyObject {
    func setData(_ data: AllContactsViewData)
    func setAvatar(id: Int, _ avatar: UIImage)
    func setOnline(id: Int, _ online: Bool)
    func startLoading()
    func stopLoading()
}

public class AllContactsPresenter {
    // MARK: Private members
    private static let MAX_LOADINGS_ALLOWED = 10

    private let context: DataContext
    private weak var view: AllContactsView?
    private let errorHandler: ErrorHandler?

    private let loadingGroup = DispatchGroup()

    private let loadingSemaphore = DispatchSemaphore(value: MAX_LOADINGS_ALLOWED)
    private let loadingQueue = DispatchQueue(label: "Loading contacts", qos: .userInitiated)
    private func setAvatarsAsync(_ contacts: Contacts) {
        if let view = self.view {
            contacts.forEach { (k, v) in
                if let email = v.email {
                    self.loadingGroup.enter()
                    loadingQueue.async {
                        self.loadingSemaphore.wait()
                        self.context.gravatar.getAvatarImage(GravatarRequest(email: email)) { (res) in
                            if let image = res.unwrap(errorHandler: self.errorHandler) {
                                view.setAvatar(id: k, image)
                            }
                            self.loadingSemaphore.signal()
                            self.loadingGroup.leave()
                        }
                    }
                }
            }
        }
    }

    private func setOnlineStatusesAsync(_ contacts: Contacts) {
        if let view = self.view {
            contacts.forEach { (k, v) in
                self.loadingGroup.enter()
                loadingQueue.async {
                    self.loadingSemaphore.wait()
                    self.context.contact.isOnline(id: k) { (res) in
                        view.setOnline(id: k, res.unwrap(errorHandler: self.errorHandler) ?? false)
                        self.loadingSemaphore.signal()
                        self.loadingGroup.leave()
                    }
                }
            }
        }
    }

    private func setContacts(_ contacts: Contacts) {
        if let view = view {
            view.setData(AllContactsViewData(
                contacts: contacts.map { (k, v) in
                    ContactViewData(
                        id: k,
                        fullName: v.fullName,
                        email: v.email) }
            ))
        }
    }

    // MARK: Public API

    public init(context: DataContext, view: AllContactsView, errorHandler: ErrorHandler? = nil) {
        self.context = context
        self.view = view
        self.errorHandler = errorHandler
    }

    public func update() {
        view?.startLoading()
        context.contact.getAllContacts { (res) in
            if let contacts = res.unwrap(errorHandler: self.errorHandler) {
                self.setContacts(contacts)
                self.setAvatarsAsync(contacts)
                self.setOnlineStatusesAsync(contacts)

            }

            self.loadingGroup.notify(queue: self.loadingQueue) {
                self.view?.stopLoading()
            }
        }
    }
}
