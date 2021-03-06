//
//  AvatarView.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 27.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import UIKit

/// View with contact avatar image and online indicator
public class AvatarView: UIView {
    internal let imageView: UIImageView
    internal let onlineView: UIImageView

    public override init(frame: CGRect) {
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .gray

        let onlineImage: UIImage? = UIImage(systemName: "circle.fill")
        onlineView = UIImageView(image: onlineImage)
        onlineView.translatesAutoresizingMaskIntoConstraints = false
        onlineView.tintColor = .green
        onlineView.layer.masksToBounds = true
        onlineView.layer.borderWidth = 1
        onlineView.layer.borderColor = UIColor.systemBackground.cgColor
        onlineView.layer.cornerRadius = 7.5

        super.init(frame: frame)
        addSubview(imageView)
        addSubview(onlineView)

        NSLayoutConstraint.activate([
            // Image constraints
            imageView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor),
            imageView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
            // Online circle constraints
            onlineView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            onlineView.widthAnchor.constraint(equalTo: onlineView.heightAnchor),
            onlineView.heightAnchor.constraint(equalToConstant: 15),
            onlineView.rightAnchor.constraint(equalTo: imageView.rightAnchor)
        ])
        
        setOnline(false)
        setImage(nil, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layerWillDraw(_ layer: CALayer) {
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
        imageView.layer.masksToBounds = true
        super.layerWillDraw(layer)
    }

    /// Sets avatar image, or default avatar, if image is nil
    /// - Parameters:
    ///   - image: Avatar image to be set
    ///   - animated: Perform animated avatar change
    public func setImage(_ image: UIImage?, animated: Bool = false) {
        let newImage = (image?.circleMasked ?? UIImage(systemName: "person.fill"))

        if animated {
            UIView.transition(
                with: self.imageView,
                duration: 0.3,
                options: .transitionCrossDissolve,
                animations: {
                    self.imageView.image = newImage
                },
                completion: nil)
        } else {
            self.imageView.image = newImage
        }
    }

    /// Sets online status
    /// - Parameters:
    ///   - online: Online status to be st
    ///   - animated: Perform animated status change
    public func setOnline(_ online: Bool, animated: Bool = false) {
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.onlineView.alpha = online ? 1.0 : 0.0
            }
        } else {
            self.onlineView.alpha = online ? 1.0 : 0.0
        }
    }
}
