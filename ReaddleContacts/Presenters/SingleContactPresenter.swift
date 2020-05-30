//
//  SingleContactPresenter.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit

public struct SingleContactViewData {
    public let id: Int
    public let fullName: String
    public let email: String?
}

public protocol SingleContactPresenterDelegate: AnyObject {
    func setData(_ data: SingleContactViewData)
    func setOnline(_ online: Bool)
    func setAvatar(_ avatar: UIImage?, animated: Bool)
    func startLoading()
    func stopLoading()
}

public class SingleContactPresenter {
    // MARK: Private members
    private let context: DataContext
    public weak var delegate: SingleContactPresenterDelegate?
    public var errorHandler: ErrorHandler?

    // MARK: Public API
    public init(context: DataContext) {
        self.context = context
    }

    /// Requests update from presenter
    public func update(id: Int, avatarSize: Int) {
        delegate?.startLoading()
        when(fulfilled:
            [
                // Get contact info and online status
                context.getContactInfoAndOnline(for: id).done { contact, online in
                    self.delegate?.setData(
                        SingleContactViewData(
                            id: id,
                            fullName: contact.fullName,
                            email: contact.email))
                    self.delegate?.setOnline(online) },
                // Get avatar image
                context.getAvatar(for: id, size: avatarSize).done { (image) in
                    self.delegate?.setAvatar(image, animated: true)
                }
            ])
            .catch({ self.errorHandler?.error($0) })
            .finally { self.delegate?.stopLoading() }
    }
}
