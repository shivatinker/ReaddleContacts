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

    func getVisibleAvatarViews() -> [Int: AvatarView]
}

public class ContactsViewContainer: UIView {

    public var contactViews: [ContactsView] = []

    public func setView(index: Int) {
        guard contactViews.indices.contains(index) else {
            fatalError("Requested index \(index) does not exists in \(ContactsViewContainer.self)")
        }
        currentView = contactViews[index]
    }

    private struct ContactAnimation {
        let image: UIImage?
        let beginFrame: CGRect
        let endFrame: CGRect
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

                if let oldView = oldValue {

                    let oldAvatars = oldView.getVisibleAvatarViews()
                    self.bringSubviewToFront(newView)

//                    setNeedsDisplay()
//                    newView.layoutSubviews()
//                    newView.reloadData()

                    newView.alpha = 0.0

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let newAvatars = newView.getVisibleAvatarViews()

                        let animations = oldAvatars.compactMap { (id, view) -> ContactAnimation? in
                            let begin = view.convert(view.bounds, to: self)
                            if let newView = newAvatars[id] {
                                let end = newView.convert(newView.bounds, to: self)
                                return ContactAnimation(
                                    image: view.imageView.image,
                                    beginFrame: begin,
                                    endFrame: end)
                            }
                            return nil
                        }

                        let tempViews = animations.map { (anim) -> (AvatarView, CGAffineTransform) in
                            let view = AvatarView(frame: anim.beginFrame)
                            view.setImage(anim.image)
                            let transform = CGAffineTransform(
                                translationX: anim.endFrame.midX - anim.beginFrame.midX,
                                y: anim.endFrame.midY - anim.beginFrame.midY)
                                .scaledBy(
                                    x: anim.endFrame.width / anim.beginFrame.width,
                                    y: anim.endFrame.height / anim.beginFrame.height)
                            return (view, transform)
                        }

                        tempViews.forEach({
                            self.addSubview($0.0)
                        })

                        newAvatars.forEach({ if oldAvatars[$0] != nil { $1.alpha = 0.0 } })
                        oldAvatars.forEach({ $1.alpha = 0.0 })
                        UIView.animate(withDuration: 0.3, animations: {
                            oldView.alpha = 0.0
                            newView.alpha = 1.0
                            tempViews.forEach { (viewTransform) in
                                viewTransform.0.transform = viewTransform.1
                            }
                        }, completion: { _ in
                            tempViews.forEach({ $0.0.removeFromSuperview() })
                            newAvatars.forEach({ if oldAvatars[$0] != nil { $1.alpha = 1.0 } })
                            oldAvatars.forEach({ $1.alpha = 1.0 })
                            oldView.removeFromSuperview()
                        })
                    }

                }
            }
        }
    }
}
