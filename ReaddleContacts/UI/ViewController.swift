//
//  ViewController.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import UIKit

class ContactTableCell: UITableViewCell {
    internal var avatarView: AvatarView!
    private var nameLabel: UILabel!

    private var data: ContactViewData!

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.setImage(nil)
        avatarView.setOnline(false)
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)

        avatarView = AvatarView()
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(avatarView)

        NSLayoutConstraint.activate([
            // Label constraints
            nameLabel.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor),
            nameLabel.leftAnchor.constraint(equalTo: avatarView.rightAnchor, constant: 5),
            nameLabel.heightAnchor.constraint(equalToConstant: 40),
            // Avatar constraints
            avatarView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor),
            avatarView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 5),
            avatarView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -5),
            avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor),
        ])
    }

    public func setData(_ data: ContactViewData) {
        DispatchQueue.main.async {
            self.nameLabel.text = data.fullName
            self.data = data
            self.avatarView.setOnline(data.online, animated: true)
        }
    }

    public func setAvatar(_ avatar: UIImage?, animated: Bool = false) {
        DispatchQueue.main.async {
            self.avatarView.setImage(avatar, animated: animated)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ContactsDataSource: NSObject {
    private var ids = [Int]()
    private var presenter: AllContactsPresenter

    private var contactCache: CachedStorage<Int, ContactViewData>
    private var avatarCache: CachedStorage<Int, UIImage>

    public func update() {
        presenter.loadContactIDs { ids in
            if let ids = ids {
                self.ids = ids
            }
        }
    }

    public func clearAvatars() {
        avatarCache.removeAll()
    }

    public init(presenter: AllContactsPresenter) {
        self.presenter = presenter

        contactCache = CachedStorage() { key, callback in
            presenter.loadContact(id: key) { callback($0) }
        }

        avatarCache = CachedStorage() { key, callback in
            presenter.loadAvatar(for: key) { callback($0) }
        }
    }

    private func getCellWithID(_ tableView: UITableView, _ id: Int) -> ContactTableCell? {
        guard let row = ids.firstIndex(of: id) else { return nil }
        return tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? ContactTableCell
    }

    private func setAvatarForId(_ tableView: UITableView, id: Int, avatar: UIImage?, animated: Bool = false) {
        DispatchQueue.main.async {
            self.getCellWithID(tableView, id)?.setAvatar(avatar, animated: animated)
        }
    }

    private func setInfoForId(_ tableView: UITableView, id: Int, data: ContactViewData) {
        DispatchQueue.main.async {
            self.getCellWithID(tableView, id)?.setData(data)
        }
    }
}

extension ContactsDataSource: UITableViewDataSourcePrefetching, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ids.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = ids[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "default") as! ContactTableCell

        contactCache.get(id) { (data, loaded) in
            if let data = data {
                self.setInfoForId(tableView, id: id, data: data)
            }
        }

        avatarCache.get(id) { (image, loaded) in
            self.setAvatarForId(tableView, id: id, avatar: image, animated: loaded)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.map({ ids[$0.row] }).forEach { (id) in
            contactCache.load(id)
            avatarCache.load(id)
        }
    }

    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        debugPrint("cancel \(indexPaths.map({ $0.row }))")
        indexPaths.map({ ids[$0.row] }).forEach { (id) in
            contactCache.remove(id)
            avatarCache.remove(id)
        }
    }
}

class ViewController: UIViewController {

    private var segmentedControl: UISegmentedControl!
    private var tableView: UITableView!
    private var shuffleButton: UIButton!
    private var activityIndicator: UIActivityIndicatorView!

    private var contactsDataSource: ContactsDataSource!
    private var presenter: AllContactsPresenter!

    @objc public func simulateButtonClicked() {
        contactsDataSource.clearAvatars()
    }

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground

        let context = DataContext(contact: MockContactsProvider(), gravatar: NetGravatarAPI(simulatedDelay: 0.5))
        presenter = AllContactsPresenter(context: context, view: self, errorHandler: nil)
        contactsDataSource = ContactsDataSource(presenter: presenter)

        shuffleButton = UIButton(type: .system)
        shuffleButton.translatesAutoresizingMaskIntoConstraints = false
        shuffleButton.setTitle("Simulate changes", for: .normal)
        shuffleButton.addTarget(self, action: #selector(simulateButtonClicked), for: .touchUpInside)
        view.addSubview(shuffleButton)

        segmentedControl = UISegmentedControl(items: ["List", "Grid"])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        view.addSubview(segmentedControl)

        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = contactsDataSource
        tableView.prefetchDataSource = contactsDataSource
        tableView.delegate = self
        tableView.register(ContactTableCell.self, forCellReuseIdentifier: "default")
        view.addSubview(tableView)
        
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

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
            // Activity indicator constraints
            activityIndicator.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5),
            activityIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5)
        ])

        contactsDataSource.update()
    }
}

extension ViewController: AllContactsView {
    func setData(_ data: AllContactsViewData) {

    }

    func startLoading() {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
        }
    }

    func stopLoading() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
}
