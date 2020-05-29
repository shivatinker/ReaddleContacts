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
    private var id: Int

    // MARK: UI
    private var avatarImageView: UIImageView = UIImageView()
    private var fullNameLabel: UILabel = UILabel()
    private var onlineLabel: UILabel = UILabel()
    private var emailLabel: UILabel = UILabel()

    init(contactId: Int, dataContext: DataContext) {
        self.id = contactId
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

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarImageView)
        fullNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fullNameLabel)
        onlineLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(onlineLabel)
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emailLabel)

        NSLayoutConstraint.activate([
            avatarImageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            avatarImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalTo: avatarImageView.heightAnchor),
            avatarImageView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.3),

            fullNameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 10),
            fullNameLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),

            onlineLabel.topAnchor.constraint(equalTo: fullNameLabel.bottomAnchor, constant: 10),
            onlineLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),

            emailLabel.topAnchor.constraint(equalTo: onlineLabel.bottomAnchor, constant: 10),
            emailLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
        ])
    }

    override func viewDidLoad() {
        initUI()

        presenter.update(id: id)
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

    func setAvatar(_ avatar: UIImage?) {
        DispatchQueue.main.async {
            self.avatarImageView.image = avatar
        }
    }

    func startLoading() {
        
    }

    func stopLoading() {
        
    }
}
