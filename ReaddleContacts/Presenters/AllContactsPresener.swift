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

/// Data, representing contact in collection
public struct ContactViewData {
    public let id: Int
    public let fullName: String
    public let email: String?
    public let online: Bool
}

/// Data, representing objects, that needs to be passed in view
public struct AllContactsViewData {
    public let contactsIds: [Int]
}

public protocol AllContactsPresenterDelegate: AnyObject {
    func setData(_ data: AllContactsViewData)
    func showContactInfo(id: Int)
    func startLoading()
    func stopLoading()
}

public class AllContactsPresenter {
    // MARK: Private members
    private let context: DataContext
    public weak var delegate: AllContactsPresenterDelegate?
    public var errorHandler: ErrorHandler?

    private class AvatarEH: ErrorHandler {
        func error(_ e: Error) {
            debugPrint("Failed to get avatar: \(e)")
        }
    }

    private let avatarErrorHandler = AvatarEH()

    // MARK: Cache
    private var avatarCache: CachedStorage<Int, UIImage>!
    private var contactCache: CachedStorage<Int, ContactViewData>!

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
    private func loadAvatar(for id: Int, size: Int, callback: @escaping (UIImage?) -> Void) {
        addTask()
        context.getAvatar(for: id, size: size)
            .done { callback($0) }
            .catch {
                self.avatarErrorHandler.error($0)
                callback(nil)
            }
            .finally { self.removeTask() }
    }

    private func loadContact(id: Int, callback: @escaping (ContactViewData?) -> Void) {
        addTask()
        context.getContactInfoAndOnline(for: id)
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
        context.contact.getAllContacts()
            .done { contacts in
                // Sorting contacts alphabeticly
                callback(contacts.sorted(by: { $0.1.fullName < $1.1.fullName }).map({ $0.0 }))
            }.catch { e in
                self.errorHandler?.error(e)
                callback(nil)
            }.finally {
                self.removeTask()
        }
    }

    // MARK: Public API

    public init(context: DataContext, errorHandler: ErrorHandler? = nil) {
        self.context = context
        self.errorHandler = errorHandler

        avatarCache = CachedStorage(maxCount: 250) { id, callback in
            self.loadAvatar(for: id, size: 50) { callback($0) }
        }

        contactCache = CachedStorage { id, callback in
            self.loadContact(id: id) { callback($0) }
        }
    }

    public func onContactSelected(id: Int) {
        delegate?.showContactInfo(id: id)
    }

    public func onSimulateChangesClicked() {
        context.simulateChanges(amount: 300).done {
            self.update()
        }.catch {
            self.errorHandler?.error($0)
        }
    }

    public func getContactInfo(id: Int, callback: @escaping (ContactViewData?, Bool) -> Void) {
        contactCache.get(id, callback)
    }

    public func getAvatar(for id: Int, callback: @escaping (UIImage?, Bool) -> Void) {
        avatarCache.get(id, callback)
    }

    public func prefetch(id: Int) {
        avatarCache.load(id)
        contactCache.load(id)
    }

    public func cancelPrefetching(id: Int) {
        context.gravatar.cancelLoading(taskId: id)
    }

    public func free(id: Int) {
        avatarCache.remove(id)
        contactCache.remove(id)
    }

    public func update() {
        loadContactIDs { (ids) in
            if let ids = ids {
                self.delegate?.setData(AllContactsViewData(contactsIds: ids))
            }
        }
    }
}
