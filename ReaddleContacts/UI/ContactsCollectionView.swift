//
//  ContactsCollectionView.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 27.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import UIKit

/// Actually in real project i'll place Table cell and Collection cell under common protocol, to avoid logic duplication

// MARK: Collection cell
/// Collection cell, containing
fileprivate class ContactCollectionCell: UICollectionViewCell {
    private var avatarView = AvatarView()

    private var data: ContactViewData?

    ///Contact ID, that this cell is going to represent
    var currentId: Int?

    static let reuseIdentifier = "default"

    override func prepareForReuse() {
        super.prepareForReuse()

        // Reset cell, so it won't contain wrong data
        setAvatar(nil)
        setData(nil)
        currentId = nil
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        // Setting up UI
        contentView.addSubview(avatarView)
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            avatarView.leftAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leftAnchor, constant: 5),
            avatarView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 5),
            avatarView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -5),
            avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor),
        ])
    }

    /// Sets contact info
    fileprivate func setData(_ data: ContactViewData?, animated: Bool = false) {
        self.data = data
        DispatchQueue.main.async {
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

// MARK: Collection class
/// UICollectionView, designated to represent contacts as grid
public class ContactsCollectionView: UICollectionView, ContactsView {
    public weak var contactsDataSource: ContactsCollectionDataSource?

    public convenience init() {
        // Initialize by default with flow layout
        self.init(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
    }

    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        register(ContactCollectionCell.self, forCellWithReuseIdentifier: ContactCollectionCell.reuseIdentifier)
        delegate = self
        dataSource = self
        prefetchDataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Extensions
extension ContactsCollectionView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contactsDataSource?.contactIds.count ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = dequeueReusableCell(withReuseIdentifier: ContactCollectionCell.reuseIdentifier, for: indexPath) as? ContactCollectionCell else {
            fatalError("Expected `\(ContactCollectionCell.self)` type for reuseIdentifier \(ContactCollectionCell.reuseIdentifier).")
        }

        if let ds = contactsDataSource {

            // Configuring cell to wait data for curernt ID
            let id = ds.contactIds[indexPath.row]
            cell.currentId = id

            ds.getContactInfo(id: id) { (data, loaded) in
                if let data = data {
                    DispatchQueue.main.async {
                        // Check if cell is still waitind for this data
                        // TODO: Cancel data tasks is them not needed more
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

extension ContactsCollectionView: UICollectionViewDataSourcePrefetching {
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if let ds = contactsDataSource {
            // Request prefetching
            ds.prefetch(ids: indexPaths.map({ ds.contactIds[$0.row] }))
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        if let ds = contactsDataSource {
            // Request cache clearing
            ds.cancelPrefetching(ids: indexPaths.map({ ds.contactIds[$0.row] }))
        }
    }
}

extension ContactsCollectionView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {

    }

}
