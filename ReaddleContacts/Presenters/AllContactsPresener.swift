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

}

public protocol AllContactsView: AnyObject {
    func setData(_ data: AllContactsViewData)
    func startLoading()
    func stopLoading()
}

public class AllContactsPresenter {
    // MARK: Private members
    private let context: DataContext
    private weak var view: AllContactsView?
    private let errorHandler: ErrorHandler?

    // MARK: Thread safe task counting
    private var currentTaskCount = 0
    private var taskCountQueue = DispatchQueue(label: "Counting current tasks")
    private var taskCountMutex = DispatchSemaphore(value: 1)
    private func taskCountSynchronized(_ f: @escaping () -> ()) {
        taskCountQueue.async {
            self.taskCountMutex.wait()
            f()
            self.taskCountMutex.signal()
        }
    }

    private func addTask() {
        taskCountSynchronized {
            if self.currentTaskCount == 0 {
                self.view?.startLoading()
            }
            self.currentTaskCount += 1
        }
    }

    private func removeTask() {
        taskCountSynchronized {
            self.currentTaskCount -= 1
            if self.currentTaskCount == 0 {
                self.view?.stopLoading()
            }
        }
    }

    // MARK: Public API

    public init(context: DataContext, view: AllContactsView, errorHandler: ErrorHandler? = nil) {
        self.context = context
        self.view = view
        self.errorHandler = errorHandler
    }

    public func loadAvatar(for id: Int, size: Int = 50, callback: @escaping (UIImage?) -> ()) {
        addTask()
        context.contact.getContact(id: id) { (res) in
            if let contact = res.unwrap(errorHandler: self.errorHandler),
                let email = contact.email {
                let request = GravatarRequest(email: email, size: size)
                self.context.gravatar.getAvatarImage(request) { (res) in
                    callback(res.unwrap(errorHandler: self.errorHandler))
                    self.removeTask()
                }
            } else {
                callback(nil)
                self.removeTask()
            }
        }
    }

    // TODO: Parallel load
    public func loadContact(id: Int, callback: @escaping (ContactViewData?) -> ()) {
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

    public func loadContactIDs(callback: @escaping ([Int]?) -> ()) {
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

    public func update() {

    }
}
