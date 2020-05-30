//
//  AllToSingleViewAnimation.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 29.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit

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
            fatalError("Expected .to VC to be \(SingleContactViewController.self)")
        }

        let toAvatar = toVC.avatarView
        toVC.view.layoutIfNeeded()
        containerView.addSubview(toVC.view)

        // Check if avatar is visible on previous view
        guard let fromAvatar =
            fromVC.contactsContainer.currentView?.getVisibleAvatarViews()[toVC.contactId] else {
                // Perform basic fade animation
                AnimationUtils.alphaAnimation(view: toVC.view, from: 0.0, to: 1.0, duration: duration).done {
                    transitionContext.completeTransition(true)
                }
                return
        }

        let animations = [
            AnimationUtils.alphaAnimation(view: toVC.view,
                                          from: 0.0,
                                          to: 1.0,
                                          duration: duration),
            AnimationUtils.travelAnimation(from: fromAvatar,
                                           to: toAvatar,
                                           in: containerView,
                                           duration: duration).done {
                if !toVC.loadFinished {
                    toAvatar.setImage(fromAvatar.imageView.image, animated: false)
                }
            }
        ]
        when(guarantees: animations).done {
            transitionContext.completeTransition(true)
        }
    }
}

class SingleToAllViewTransition: NSObject, UIViewControllerAnimatedTransitioning {
    let duration = 0.3

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        guard let fromVC = transitionContext.viewController(forKey: .from) as? SingleContactViewController else {
            fatalError("Expected .from VC to be \(SingleContactViewController.self)")
        }
        guard let toVC = transitionContext.viewController(forKey: .to) as? AllContactsViewController else {
            fatalError("Expected .to VC to be \(AllContactsViewController.self)")
        }

        let fromAvatar = fromVC.avatarView
        toVC.view.layoutIfNeeded()
        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)

        // Check if avatar is visible on previous view
        guard let toAvatar =
            toVC.contactsContainer.currentView?.getVisibleAvatarViews()[fromVC.contactId] else {
                // Perform basic fade animation
                AnimationUtils.alphaAnimation(view: fromVC.view, from: 1.0, to: 0.0, duration: duration).done {
                    transitionContext.completeTransition(true)
                }
                return
        }
        
        let animations = [
            AnimationUtils.alphaAnimation(view: fromVC.view,
                                          from: 1.0,
                                          to: 0.0,
                                          duration: duration),
            AnimationUtils.travelAnimation(from: fromAvatar,
                                           to: toAvatar,
                                           in: containerView,
                                           duration: duration)
        ]
        when(guarantees: animations).done {
            transitionContext.completeTransition(true)
        }
    }
}
