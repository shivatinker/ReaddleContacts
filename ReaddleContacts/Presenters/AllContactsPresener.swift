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
    public let contactsIds: [Int]
}

public protocol AllContactsPresenterDelegate: AnyObject {
    func setData(_ data: AllContactsViewData)
    func startLoading()
    func stopLoading()
}

public class AllContactsPresenter {
    // MARK: Private members
    private let context: DataContext
    private weak var delegate: AllContactsPresenterDelegate?
    private let errorHandler: ErrorHandler?

    private class AvatarEH: ErrorHandler {
        func error(_ e: Error) {
            if let e = e as? NetError,
                case .requestCancelled = e {
                // Request was cancelled
                return
            }
            debugPrint("Failed to get avatar: \(e)")
        }
    }
    private let avatarErrorHandler = AvatarEH()

    // MARK: Cache
    private var avatarCache: CachedStorage<Int, UIImage>?
    private var contactCache: CachedStorage<Int, ContactViewData>?

    // MARK: Thread safe task counting
    private var currentTaskCount = 0
    private var taskCountQueue = DispatchQueue(label: "Counting current tasks")
    private var taskCountMutex = DispatchSemaphore(value: 1)
    private func taskCountSynchronized(_ f: @escaping () -> Void) {
        taskCountQueue.async {
            self.taskCountMutex.wait()
            f()
            self.taskCountMutex.signal()
        }
    }

    private func addTask() {
        taskCountSynchronized {
            if self.currentTaskCount == 0 {
                self.delegate?.startLoading()
            }
            self.currentTaskCount += 1
        }
    }

    private func removeTask() {
        taskCountSynchronized {
            self.currentTaskCount -= 1
            if self.currentTaskCount == 0 {
                self.delegate?.stopLoading()
            }
        }
    }


    // MARK: Private core functions
    private func loadAvatar(for id: Int, callback: @escaping (UIImage?) -> Void) {
        addTask()
        context.contact.getContact(id: id) { (res) in
            if let contact = res.unwrap(errorHandler: self.errorHandler),
                let email = contact.email {
                let request = GravatarRequest(email: email, taskId: id)
                self.context.gravatar.getAvatarImage(request) { (res) in
                    callback(res.unwrap(errorHandler: self.avatarErrorHandler) ?? nil)
                    self.removeTask()
                }
            } else {
                callback(nil)
                self.removeTask()
            }
        }
    }

    private func loadContact(id: Int, callback: @escaping (ContactViewData?) -> Void) {
        addTask()
        context.contact.getContact(id: id) { (res) in
            if let contact = res.unwrap(errorHandler: self.errorHandler) {
                self.context.contact.isOnline(id: id) { (res) in
                    callback(ContactViewData(
                        id: id,
                        fullName: contact.fullName,
                        email: contact.email,
                        online: res.unwrap(errorHandler: self.errorHandler) ?? false))
                    self.removeTask()
                }
            } else {
                callback(nil)
                self.removeTask()
            }
        }
    }

    private func loadContactIDs(callback: @escaping ([Int]?) -> Void) {
        addTask()
        context.contact.getAllContacts { (res) in
            if let contacts = res.unwrap(errorHandler: self.errorHandler) {
                callback(contacts.sorted(by: { (e1, e2) -> Bool in
                    e1.1.fullName < e2.1.fullName
                }).map({ $0.0 }))
                self.removeTask()
            } else {
                callback(nil)
                self.removeTask()
            }
        }
    }

    // MARK: Public API

    public init(context: DataContext, view: AllContactsPresenterDelegate, errorHandler: ErrorHandler? = nil) {
        self.context = context
        self.delegate = view
        self.errorHandler = errorHandler

        avatarCache = CachedStorage(maxCount: 250) { id, callback in
            self.loadAvatar(for: id) { callback($0) }
        }

        contactCache = CachedStorage { id, callback in
            self.loadContact(id: id) { callback($0) }
        }

    }

    public func getContactInfo(id: Int, callback: @escaping (ContactViewData?, Bool) -> Void) {
        contactCache?.get(id, callback) ?? callback(nil, false)
    }

    public func getAvatar(for id: Int, callback: @escaping (UIImage?, Bool) -> Void) {
        avatarCache?.get(id, callback) ?? callback(nil, false)
    }

    public func prefetch(id: Int) {
        avatarCache?.load(id)
        contactCache?.load(id)
    }

    public func cancelPrefetching(id: Int) {
        context.gravatar.cancelLoading(taskId: id)
    }

    public func free(id: Int) {
        avatarCache?.remove(id)
        contactCache?.remove(id)
    }

    public func update() {
        loadContactIDs { (ids) in
            if let ids = ids {
                self.delegate?.setData(AllContactsViewData(contactsIds: ids))
            }
        }
    }
}
