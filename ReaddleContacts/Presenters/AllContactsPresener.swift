//
//  AllContactsPresener.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit

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
    private func addTask() {
        taskCountQueue.async {
            if self.currentTaskCount == 0 {
                self.delegate?.startLoading()
            }
            self.currentTaskCount += 1
        }
    }

    private func removeTask() {
        taskCountQueue.async {
            self.currentTaskCount -= 1
            if self.currentTaskCount == 0 {
                self.delegate?.stopLoading()
            }
        }
    }

    // MARK: Private core functions
    private func loadAvatar(for id: Int, callback: @escaping (UIImage?) -> Void) {
        addTask()
        context.getAvatarP(for: id)
            .done { callback($0) }
            .catch {
                self.avatarErrorHandler.error($0)
                callback(nil)
            }
            .finally { self.removeTask() }
    }

    private func loadContact(id: Int, callback: @escaping (ContactViewData?) -> Void) {
        addTask()
        context.getContactInfoAndOnlineP(for: id)
            .done { contact, online in
                let contactData = ContactViewData(
                    id: id,
                    fullName: contact.fullName,
                    email: contact.email,
                    online: online)
                callback(contactData)
            }.catch {
                self.errorHandler?.error($0)
                callback(nil)
            }.finally { self.removeTask() }
    }

    private func loadContactIDs(callback: @escaping ([Int]?) -> Void) {
        addTask()
        context.getAllContactP()
            .done { contacts in
                // Sorting contacts alphabeticly
                callback(contacts.sorted(by: { $0.1.fullName < $1.1.fullName }).map({ $0.0 }))
            }.catch {
                self.errorHandler?.error($0)
                callback(nil)
            }.finally { self.removeTask() }
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
