//
//  ContactsTableView.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 27.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import UIKit

// MARK: Table cell
private class ContactTableCell: UITableViewCell {
    internal var avatarView: AvatarView!
    private var nameLabel: UILabel!

    private var data: ContactViewData!

    public override func prepareForReuse() {
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

    public func setData(_ data: ContactViewData, animated: Bool = false) {
        DispatchQueue.main.async {
            self.nameLabel.text = data.fullName
            self.data = data
            self.avatarView.setOnline(data.online, animated: animated)
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

// MARK: Table class
public class ContactsTableView: UITableView, ContactsView {
    public static let rHeight = 50.0
    public weak var contactsDataSource: ContactsCollectionDataSource?

    public override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        register(ContactTableCell.self, forCellReuseIdentifier: "default")
        delegate = self
        dataSource = self
        rowHeight = CGFloat(Self.rHeight)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getCellWithID(_ id: Int) -> ContactTableCell? {
        guard let row = contactsDataSource?.contactIds.firstIndex(of: id) else { return nil }
        return cellForRow(at: IndexPath(row: row, section: 0)) as? ContactTableCell
    }

    private func setAvatarForId(id: Int, avatar: UIImage?, animated: Bool = false) {
        self.getCellWithID(id)?.setAvatar(avatar, animated: animated)
    }

    private func setInfoForId(id: Int, data: ContactViewData, animated: Bool = false) {
        self.getCellWithID(id)?.setData(data, animated: animated)
    }
}

extension ContactsTableView: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactsDataSource?.contactIds.count ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "default") as! ContactTableCell
        if let ds = contactsDataSource {
            let id = ds.contactIds[indexPath.row]

            ds.getContactInfo(id: id) { (data, loaded) in
                if let data = data {
                    DispatchQueue.main.async {
                        self.setInfoForId(id: id, data: data, animated: loaded)
                    }
                }
            }

            ds.getAvatar(id: id) { (image, loaded) in
                DispatchQueue.main.async {
                    self.setAvatarForId(id: id, avatar: image, animated: loaded)
                }
            }
        }
        return cell
    }
}

extension ContactsTableView: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if let ds = contactsDataSource {
            ds.prefetch(ids: indexPaths.map({ ds.contactIds[$0.row] }))
        }
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        if let ds = contactsDataSource {
            ds.cancelPrefetching(ids: indexPaths.map({ ds.contactIds[$0.row] }))
        }
    }
}

extension ContactsTableView: UITableViewDelegate {
    
}
