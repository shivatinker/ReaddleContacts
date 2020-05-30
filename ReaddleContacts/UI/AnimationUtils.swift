//
//  AnimationUtils.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 30.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit

class AnimationUtils {
    private init() { }

    public static func travelAnimation(from: AvatarView,
                                       to: AvatarView,
                                       in container: UIView,
                                       duration: TimeInterval = 0.3) -> Guarantee<Void> {
        let beginFrame = from.convert(from.bounds, to: container)
        let endFrame = to.convert(to.bounds, to: container)

        let transitionView = AvatarView(frame: beginFrame)
        transitionView.setOnline(false)
        transitionView.setImage(from.imageView.image)
        container.addSubview(transitionView)

        from.alpha = 0.0
        to.alpha = 0.0

        return UIView.animate(.promise, duration: duration) {
            transitionView.transform = CGAffineTransform(
                translationX: endFrame.midX - beginFrame.midX, y: endFrame.midY - beginFrame.midY)
                .scaledBy(x: endFrame.width / beginFrame.width, y: endFrame.height / beginFrame.height)
        }.done { _ in
            from.alpha = 1.0
            to.alpha = 1.0
            transitionView.removeFromSuperview()
        }
    }

    public static func alphaAnimation(view: UIView,
                                      from: CGFloat,
                                      to: CGFloat,
                                      duration: TimeInterval = 0.3) -> Guarantee <Void> {
        view.alpha = from
        return UIView.animate(.promise, duration: duration) {
            view.alpha = to
        }.asVoid()
    }
}
