//
//  ViewController.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import UIKit

class ContactTableCell: UITableViewCell {

    private var avatarView: UIImageView!
    private var nameLabel: UILabel!
    private var onlineView: UIImageView!

    private var data: ContactViewData!
    public var currentID: Int {
        data.id
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        avatarView = UIImageView(image: UIImage(systemName: "circle.fill"))
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.layer.masksToBounds = true
        addSubview(avatarView)

        nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        let onlineImage: UIImage? = UIImage(systemName: "circle.fill")
        onlineView = UIImageView(image: onlineImage)
        onlineView.translatesAutoresizingMaskIntoConstraints = false
        onlineView.tintColor = .green
        onlineView.layer.masksToBounds = true
        onlineView.layer.borderWidth = 1
        onlineView.layer.borderColor = UIColor.white.cgColor
        addSubview(onlineView)

        NSLayoutConstraint.activate([
            // Label constraints
            nameLabel.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            nameLabel.leftAnchor.constraint(equalTo: avatarView.rightAnchor, constant: 5),
            nameLabel.heightAnchor.constraint(equalToConstant: 40),
            // Avatar constraints
            avatarView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 5),
            avatarView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 5),
            avatarView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -5),
            avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor),
            // Online circle constraints
            onlineView.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),
            onlineView.widthAnchor.constraint(equalTo: onlineView.heightAnchor),
            onlineView.heightAnchor.constraint(equalToConstant: 15),
            onlineView.rightAnchor.constraint(equalTo: avatarView.rightAnchor),
        ])

        onlineView.layer.cornerRadius = 7.5
    }

    public func setData(_ data: ContactViewData) {
        nameLabel.text = data.fullName
        self.data = data
    }

    public func setAvatar(_ avatar: UIImage?, animated: Bool = false) {
        avatarView.image = avatar
        avatarView.layer.cornerRadius = avatarView.frame.size.width / 2

        if animated {
            avatarView.alpha = 0.0
            UIView.animate(withDuration: 0.5) {
                self.avatarView.alpha = 1.0
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ContactsDataSource: NSObject {
    public var contacts = [ContactViewData]()
    public var avatars = [Int: UIImage]()
}

extension ContactsDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let i = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "default") as! ContactTableCell
        cell.setData(contacts[i])
        cell.setAvatar(avatars[contacts[i].id])
        return cell
    }
}

class ViewController: UIViewController {

    private var segmentedControl: UISegmentedControl!
    private var tableView: UITableView!
    private var shuffleButton: UIButton!

    private let contactsDataSource = ContactsDataSource()
    private var presenter: AllContactsPresenter!

    override func loadView() {
        view = UIView()
        view.backgroundColor = .white

        shuffleButton = UIButton(type: .system)
        shuffleButton.translatesAutoresizingMaskIntoConstraints = false
        shuffleButton.setTitle("Simulate changes", for: .normal)
        view.addSubview(shuffleButton)

        segmentedControl = UISegmentedControl(items: ["List", "Grid"])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        view.addSubview(segmentedControl)

        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = contactsDataSource
        tableView.delegate = self
        tableView.register(ContactTableCell.self, forCellReuseIdentifier: "default")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            // Button constraints
            shuffleButton.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            shuffleButton.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            shuffleButton.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            shuffleButton.heightAnchor.constraint(equalToConstant: 40),
            // Seg constraints
            segmentedControl.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            segmentedControl.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor, constant: 50),
            segmentedControl.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor, constant: -50),
            segmentedControl.heightAnchor.constraint(equalToConstant: 25),
            // Table constraints
            tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 5),
            tableView.bottomAnchor.constraint(equalTo: shuffleButton.topAnchor, constant: 5),
            tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
        ])

        let context = DataContext(contact: MockContactsProvider(), gravatar: NetGravatarAPI(simulatedDelay: 0.5))
        presenter = AllContactsPresenter(context: context, view: self, errorHandler: nil)
        presenter.update()
    }
}

extension ViewController: AllContactsView {
    func setData(_ data: AllContactsViewData) {
        DispatchQueue.main.async {
            self.contactsDataSource.contacts = data.contacts
            self.tableView.reloadData()
        }
    }

    func setAvatar(id: Int, _ avatar: UIImage) {
        DispatchQueue.main.async {
            self.contactsDataSource.avatars[id] = avatar
            for c in self.tableView.visibleCells {
                if let c = c as? ContactTableCell,
                    c.currentID == id {
                    c.setAvatar(avatar, animated: true)
                }
            }
        }
    }

    func setOnline(id: Int, _ online: Bool) {

    }

    func startLoading() {
        print("Start loading")
    }

    func stopLoading() {
        print("Stop loading")
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
}
