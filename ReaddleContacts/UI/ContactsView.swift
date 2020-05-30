//
//  ContactsView.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 27.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit

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

    func getVisibleAvatarViews() -> [Int: AvatarView]
}

public class ContactsViewContainer: UIView {

    public var contactViews: [ContactsView] = []
    private var currentIndex: Int = 0

    public func setView(index: Int) {
        guard contactViews.indices.contains(index) else {
            fatalError("Requested index \(index) does not exists in \(ContactsViewContainer.self)")
        }
        currentView = contactViews[index]
        currentIndex = index
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        let swipeleft = UISwipeGestureRecognizer(target: self, action: #selector(swipe(_:)))
        swipeleft.direction = [.left]
        addGestureRecognizer(swipeleft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipe(_:)))
        swipeRight.direction = [.right]
        addGestureRecognizer(swipeRight)
    }

    @objc public func swipe(_ gesture: UISwipeGestureRecognizer) {
        if gesture.state == .recognized {
            if gesture.direction == .right {
                if currentIndex > 0 {
                    setView(index: currentIndex - 1)
                }
            } else {
                if currentIndex < contactViews.count - 1 {
                    setView(index: currentIndex + 1)
                }
            }
        }
    }

    var currentView: ContactsView? {
        didSet {
            if let newView = currentView {
                newView.translatesAutoresizingMaskIntoConstraints = false
                self.addSubview(newView)

                NSLayoutConstraint.activate([
                    newView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
                    newView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
                    newView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor),
                    newView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor)
                ])

                var animations = [Guarantee<Void>]()
                if let oldView = oldValue {
                    let oldAvatars = oldView.getVisibleAvatarViews()
                    self.bringSubviewToFront(newView)
                    after(.milliseconds(10)).done {
                        let newAvatars = newView.getVisibleAvatarViews()
                        for (id, from) in oldAvatars {
                            if let to = newAvatars[id] {
                                animations.append(AnimationUtils.travelAnimation(from: from,
                                                                                 to: to,
                                                                                 in: self,
                                                                                 duration: 0.3))
                            }
                        }
                    }
                    animations.append(AnimationUtils.alphaAnimation(view: oldView,
                                                                    from: 1.0,
                                                                    to: 0.0,
                                                                    duration: 0.3))
                }

                animations.append(AnimationUtils.alphaAnimation(view: newView,
                                                                from: 0.0,
                                                                to: 1.0,
                                                                duration: 0.3))
            }
        }
    }
}
