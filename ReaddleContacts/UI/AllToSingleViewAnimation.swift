//
//  AllToSingleViewAnimation.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 29.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import UIKit

class AllToSingleViewAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let duration = 0.3

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard let fromVC = transitionContext.viewController(forKey: .from) as? AllContactsViewController else {
            fatalError("Expected .from VC to be \(AllContactsViewController.self)")
        }
        guard let toVC = transitionContext.viewController(forKey: .to) as? SingleContactViewController else {
            fatalError("Expected .from VC to be \(SingleContactViewController.self)")
        }
        let newAvatarView = toVC.avatarImageView

        toVC.view.layoutIfNeeded()
        containerView.addSubview(toVC.view)

        // Check if avatar is visible on previous view
        guard let collectionAvatarView = fromVC.getAvatarImageView(for: toVC.contactId) else {
            // Perform basic fade animation
            toVC.view.alpha = 0
            UIView.animate(
                withDuration: duration,
                animations: { toVC.view.alpha = 1.0 },
                completion: { _ in transitionContext.completeTransition(true) }
            )
            return
        }

        // Prepare views
        newAvatarView.alpha = 0.0
        collectionAvatarView.alpha = 0.0
        toVC.view.alpha = 0

        // Calculate frames in containerView
        let beginFrame: CGRect = collectionAvatarView.convert(collectionAvatarView.bounds, to: containerView)
        let endFrame = newAvatarView.convert(newAvatarView.bounds, to: containerView)

        // Add temp view in same place as old avatar
        let transitionView = UIImageView(frame: beginFrame)
        transitionView.image = collectionAvatarView.image
        transitionView.layer.cornerRadius = transitionView.frame.size.width / 2
        transitionView.layer.masksToBounds = true
        transitionView.tintColor = .gray
        containerView.addSubview(transitionView)

        // Preform animation
        UIView.animate(
            withDuration: duration,
            animations: {
                transitionView.frame = endFrame
                transitionView.layer.cornerRadius = transitionView.frame.size.width / 2
                transitionView.layer.masksToBounds = true
                toVC.view.alpha = 1.0
            },
            completion: { _ in
                // If new view still not loaded hi-res avatar, load low-res avatar for a while
                if !toVC.loadFinished {
                    toVC.setAvatar(transitionView.image, animated: false)
                }
                newAvatarView.alpha = 1.0
                collectionAvatarView.alpha = 1.0
                transitionView.removeFromSuperview()
                transitionContext.completeTransition(true)
            })
    }
}
