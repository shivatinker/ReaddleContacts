//
//  ContactsView.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 27.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import UIKit

/// Cached data source for UIViews that can display collections of contacts
public protocol ContactsCollectionDelegate: AnyObject {
    /// Contains ID's to display
    var contactIds: [Int] { get }

    /// Gets contact info async
    /// - Parameters:
    ///   - id: Contact ID
    ///   - callback: second value will be false if data was already cached
    func getContactInfo(id: Int, callback: @escaping (ContactViewData?, Bool) -> Void)

    /// Gets avatar image async
    /// - Parameters:
    ///   - id: Contact ID
    ///   - callback: second value will be false if image was already cached
    func getAvatarImage(id: Int, callback: @escaping (UIImage?, Bool) -> Void)

    /// Requests data prefetching for contacts
    /// - Parameter ids: Contacts ID's to prefetch
    func prefetch(ids: [Int])

    /// Requests cancelling all pending data tasks on selected contacts
    /// - Parameter ids: Contacts ID's to cancel
    func cancelPrefetching(ids: [Int])

    func onContactSelected(id: Int)
}

/// UIView, thet displays collection of contacts
public protocol ContactsView: UIView {
    /// Data source
    var contactsDelegate: ContactsCollectionDelegate? { get set }

    /// Requests immediate data reloading, for example if item count has chenged
    func reloadData()

    func getAvatarImageView(for id: Int) -> UIImageView?
}
