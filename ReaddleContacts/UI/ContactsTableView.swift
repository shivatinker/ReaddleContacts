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
/// Table cell, containing contact avatar, online status and full name
fileprivate class ContactTableCell: UITableViewCell {
    private var avatarView: AvatarView = AvatarView()
    private var nameLabel: UILabel = UILabel()

    private var data: ContactViewData?

    ///Contact ID, that this cell is going to represent
    var currentId: Int?

    static let reuseIdentifier = "default"

    public override func prepareForReuse() {
        super.prepareForReuse()

        // Reset cell, so it won't contain wrong data
        setData(nil)
        setAvatar(nil)
        currentId = nil
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // Setting up UI
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        avatarView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(avatarView)

        NSLayoutConstraint.activate([
            // Label constraints
            nameLabel.centerYAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.centerYAnchor),
            nameLabel.leftAnchor.constraint(equalTo: avatarView.rightAnchor, constant: 5),
            // Avatar constraints
            avatarView.leftAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leftAnchor),
            avatarView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 5),
            avatarView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -5),
            avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor),
        ])
    }

    /// Sets contact information
    fileprivate func setData(_ data: ContactViewData?, animated: Bool = false) {
        self.data = data
        DispatchQueue.main.async {
            self.nameLabel.text = data?.fullName ?? ""
            self.avatarView.setOnline(data?.online ?? false, animated: animated)
        }
    }

    /// Sets avatar image
    fileprivate func setAvatar(_ avatar: UIImage?, animated: Bool = false) {
        DispatchQueue.main.async {
            self.avatarView.setImage(avatar, animated: animated)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Table class
/// UITableView, designated to represent contacts as list
public class ContactsTableView: UITableView, ContactsView {
    /// Constant row height
    public static let rHeight = 50.0
    public weak var contactsDataSource: ContactsCollectionDataSource?

    public override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        register(ContactTableCell.self, forCellReuseIdentifier: ContactTableCell.reuseIdentifier)
        delegate = self
        dataSource = self
        prefetchDataSource = self
        rowHeight = CGFloat(Self.rHeight)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Extensions
extension ContactsTableView: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactsDataSource?.contactIds.count ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableCell.reuseIdentifier) as? ContactTableCell else {
            fatalError("Expected `\(ContactTableCell.self)` type for reuseIdentifier \(ContactTableCell.reuseIdentifier).")
        }

        if let ds = contactsDataSource {

            // Configuring cell to wait data for curernt ID
            let id = ds.contactIds[indexPath.row]
            cell.currentId = id

            ds.getContactInfo(id: id) { (data, loaded) in
                if let data = data {
                    DispatchQueue.main.async {
                        // Check if cell is still waitind for this data
                        if cell.currentId == id {
                            // Also, display data animated only if data was loaded from net
                            cell.setData(data, animated: loaded)
                        }
                    }
                }
            }

            ds.getAvatarImage(id: id) { (image, loaded) in
                DispatchQueue.main.async {
                    // Check if cell is still waitind for avatar image
                    if cell.currentId == id {
                        // Also, display avatar animated only if data was loaded from net
                        cell.setAvatar(image, animated: loaded)
                    }
                }
            }
        }
        return cell
    }
}

extension ContactsTableView: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if let ds = contactsDataSource {
            // Request prefetching
            ds.prefetch(ids: indexPaths.map({ ds.contactIds[$0.row] }))
        }
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        if let ds = contactsDataSource {
            // Request cache clearing
            ds.cancelPrefetching(ids: indexPaths.map({ ds.contactIds[$0.row] }))
        }
    }
}

extension ContactsTableView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {

    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let ds = contactsDataSource {
            ds.free(ids: [ds.contactIds[indexPath.row]])
        }
    }
}
