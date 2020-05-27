//
//  ViewController.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import UIKit

class ContactTableCell: UITableViewCell {

    public static let AVATAR_SIZE = 50

    internal var avatarView: UIImageView!
    private var nameLabel: UILabel!
    private var onlineView: UIImageView!

    private var data: ContactViewData!
    public var currentID: Int? {
        data?.id
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = UIImage(systemName: "circle.fill")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        avatarView = UIImageView(image: UIImage(systemName: "circle.fill"))
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.layer.masksToBounds = true
        avatarView.tintColor = .gray
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
        DispatchQueue.main.async {
            self.nameLabel.text = data.fullName
            self.data = data
        }
    }

    public func setAvatar(_ avatar: UIImage?, animated: Bool = false) {
        DispatchQueue.main.async {
            self.avatarView.image = avatar
            self.avatarView.layer.cornerRadius = self.avatarView.frame.size.width / 2

            if animated {
                self.avatarView.alpha = 0.0
                UIView.animate(withDuration: 0.5) {
                    self.avatarView.alpha = 1.0
                }
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ContactsDataSource: NSObject {
    private var ids = [Int]()
    private var contactCache = [Int: ContactViewData]()
    private var avatarCache = [Int: UIImage]()

    private var presenter: AllContactsPresenter

    private func loadAvatarForId(_ id: Int, callback: ((UIImage, Bool) -> ())? = nil) {
        if let image = avatarCache[id] {
            callback?(image, false)
        } else {
            presenter.loadAvatar(for: id, size: ContactTableCell.AVATAR_SIZE) { (image) in
                self.avatarCache[id] = image
                callback?(image, true)
            }
        }
    }

    private func loadInfoForId(_ id: Int, callback: ((ContactViewData, Bool) -> ())? = nil) {
        if let data = contactCache[id] {
            callback?(data, false)
        } else {
            presenter.loadContact(id: id) { (data) in
                self.contactCache[id] = data
                callback?(data, true)
            }
        }
    }

    public func update() {
        presenter.loadContactIDs(callback: { self.ids = $0 })
    }

    public init(presenter: AllContactsPresenter) {
        self.presenter = presenter
    }

    private func getCellWithID(_ tableView: UITableView, _ id: Int) -> ContactTableCell? {
        guard let row = ids.firstIndex(of: id) else { return nil }
        return tableView.cellForRow(at: IndexPath(row: row, section: 0)) as? ContactTableCell
    }
}

extension ContactsDataSource: UITableViewDataSourcePrefetching, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ids.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        debugPrint("rowat \(indexPath.row)")
        let id = ids[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "default") as! ContactTableCell

        loadInfoForId(id) { data, loaded in
            DispatchQueue.main.async {
                self.getCellWithID(tableView, id)?.setData(data)
            }
        }
        loadAvatarForId(id) { image, loaded in
            DispatchQueue.main.async {
                self.getCellWithID(tableView, id)?.setAvatar(image, animated: loaded)
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.map({ ids[$0.row] }).forEach { (id) in
            loadInfoForId(id)
            loadAvatarForId(id)
        }
    }

    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.map({ ids[$0.row] }).forEach { (id) in
            self.contactCache[id] = nil
            self.avatarCache[id] = nil
        }
    }
}

class ViewController: UIViewController {

    private var segmentedControl: UISegmentedControl!
    private var tableView: UITableView!
    private var shuffleButton: UIButton!

    private var contactsDataSource: ContactsDataSource!
    private var presenter: AllContactsPresenter!

    override func loadView() {
        view = UIView()
        view.backgroundColor = .white

        let context = DataContext(contact: MockContactsProvider(), gravatar: NetGravatarAPI(simulatedDelay: 0.5))
        presenter = AllContactsPresenter(context: context, view: self, errorHandler: nil)
        contactsDataSource = ContactsDataSource(presenter: presenter)

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
        tableView.prefetchDataSource = contactsDataSource
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

        contactsDataSource.update()
    }
}

extension ViewController: AllContactsView {
    func setData(_ data: AllContactsViewData) {

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
