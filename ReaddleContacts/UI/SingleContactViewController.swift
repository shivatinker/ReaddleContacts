//
//  SingleContactViewController.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 29.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import UIKit

class SingleContactViewController: UIViewController {
    private var presenter: SingleContactPresenter

    /// Contact id to display
    private(set) var contactId: Int
    private(set) var loadFinished: Bool = false

    // MARK: UI
    internal let avatarView: AvatarView = AvatarView()
    private let fullNameLabel: UILabel = UILabel()
    private let onlineLabel: UILabel = UILabel()
    private let emailLabel: UITextView = UITextView()

    init(contactId: Int, dataContext: DataContext) {
        self.contactId = contactId
        self.presenter = SingleContactPresenter(context: dataContext)
        super.init(nibName: nil, bundle: nil)
        presenter.delegate = self
        presenter.errorHandler = AlertErrorHandler(parent: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initUI() {
        view = UIView()
        view.backgroundColor = .systemBackground

        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.tintColor = .gray
        avatarView.setOnline(false)
//        avatarImageView.clipsToBounds = true
        view.addSubview(avatarView)
        fullNameLabel.translatesAutoresizingMaskIntoConstraints = false
        fullNameLabel.adjustsFontSizeToFitWidth = true
        fullNameLabel.font = .systemFont(ofSize: 30)
        fullNameLabel.textAlignment = .center
        view.addSubview(fullNameLabel)
        onlineLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(onlineLabel)
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.isEditable = false
        emailLabel.dataDetectorTypes = .link
        emailLabel.isScrollEnabled = false
        emailLabel.font = UIFont.systemFont(ofSize: 22)
        view.addSubview(emailLabel)

        NSLayoutConstraint.activate([
            avatarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            avatarView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor),
            avatarView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.4),

            fullNameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 10),
            fullNameLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 10),
            fullNameLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10),
            fullNameLabel.heightAnchor.constraint(equalToConstant: 50),

            onlineLabel.topAnchor.constraint(equalTo: fullNameLabel.bottomAnchor, constant: 10),
            onlineLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),

            emailLabel.topAnchor.constraint(equalTo: onlineLabel.bottomAnchor, constant: 10),
            emailLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.delegate = nil
    }

    override func viewDidLoad() {
        initUI()
        presenter.update(id: contactId, avatarSize: 250)
    }
}

extension SingleContactViewController: SingleContactPresenterDelegate {
    func setData(_ data: SingleContactViewData) {
        DispatchQueue.main.async {
            self.fullNameLabel.text = data.fullName
            self.emailLabel.text = data.email ?? "No email"
        }
    }

    func setOnline(_ online: Bool) {
        DispatchQueue.main.async {
            self.onlineLabel.text = online ? "online" : "offline"
        }
    }
    
    func setAvatar(_ avatar: UIImage?, animated: Bool = true) {
        DispatchQueue.main.async {
            let anim = {
                self.avatarView.setImage(avatar)
            }
            if animated {
                UIView.transition(
                    with: self.avatarView,
                    duration: 0.3,
                    options: .transitionCrossDissolve,
                    animations: anim,
                    completion: nil)
            } else {
                anim()
            }
        }
    }

    func startLoading() {
        DispatchQueue.main.async {
            self.loadFinished = false
        }
    }

    func stopLoading() {
        DispatchQueue.main.async {
            self.loadFinished = true
        }
    }
}
