//
//  SingleContactViewPresenter.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import UIKit

public struct SingleContactViewData {
    public let id: Int
    public let fullName: String
    public let email: String?
}

public protocol SingleContactView: AnyObject {
    func setData(_ data: SingleContactViewData)
    func setOnline(_ online: Bool)
    func setAvatar(_ avatar: UIImage?)
    func startLoading()
    func stopLoading()
}

public class SingleContactPresenter {
    // MARK: Private members
    private let context: DataContext
    private weak var view: SingleContactView?
    private let errorHandler: ErrorHandler?
    private let loadingGroup = DispatchGroup()

    // MARK: Public API
    public init(context: DataContext, view: SingleContactView, errorHandler: ErrorHandler? = nil) {
        self.context = context
        self.view = view
        self.errorHandler = errorHandler
    }

    public func update(id: Int) {
        view?.startLoading()
        context.contact.getContact(id: id) { (res) in
            // Load contact information async
            if let contact = res.unwrap(errorHandler: self.errorHandler) {
                self.view?.setData(SingleContactViewData(
                    id: id,
                    fullName: contact.fullName,
                    email: contact.email))

                // Load online status
                self.loadingGroup.enter()
                self.context.contact.isOnline(id: id) { (res) in
                    self.view?.setOnline(res.unwrap(errorHandler: self.errorHandler) ?? false)
                    self.loadingGroup.leave()
                }

                // Load avatar
                if let email = contact.email {
                    self.loadingGroup.enter()
                    self.context.gravatar.getAvatarImage(GravatarRequest(email: email)) { (res) in
                        if let avatar = res.unwrap(errorHandler: self.errorHandler) {
                            self.view?.setAvatar(avatar)
                        }
                        self.loadingGroup.leave()
                    }
                }
            }

            // After all info is loaded notify view
            self.loadingGroup.notify(queue: DispatchQueue.global(qos: .userInitiated)) {
                self.view?.stopLoading()
            }
        }
    }
}
