//
//  ViewController.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import UIKit

class AllContactsViewController: UIViewController {

    private var presenter: AllContactsPresenter?
    /// Contact IDs to display
    private var ids: [Int]?

    // MARK: UI
    private var segmentedControl: UISegmentedControl!
    private var contactsPlaceholder: UIView!
    private var shuffleButton: UIButton!
    private var activityIndicator: UIActivityIndicatorView!

    /// Current contacts display view, for now it can be table or collection
    private var contactsView: ContactsView?

    private enum ContactsStyle {
        case grid
        case list
    }
    private var currentStyle: ContactsStyle? = nil

    /// Removes old contacts view and replaces it so only on ContactView stays in memory
    private func setContactsView(_ v: ContactsView) {
        contactsView?.removeFromSuperview()

        contactsPlaceholder.addSubview(v)
        v.contactsDataSource = self

        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: contactsPlaceholder.safeAreaLayoutGuide.topAnchor),
            v.bottomAnchor.constraint(equalTo: contactsPlaceholder.safeAreaLayoutGuide.bottomAnchor),
            v.leftAnchor.constraint(equalTo: contactsPlaceholder.safeAreaLayoutGuide.leftAnchor),
            v.rightAnchor.constraint(equalTo: contactsPlaceholder.safeAreaLayoutGuide.rightAnchor),
        ])

        contactsView = v

        // Request update from presenter
        presenter?.update()
    }

    private func setContactsStyle(_ style: ContactsStyle) {
        if style == currentStyle {
            return
        }

        switch style {
        case .grid:
            setContactsView(ContactsCollectionView())
        case .list:
            setContactsView(ContactsTableView())
        }
    }

    private func initUI() {
        // UI Init
        view = UIView()
        view.backgroundColor = .systemBackground

        shuffleButton = UIButton(type: .system)
        shuffleButton.translatesAutoresizingMaskIntoConstraints = false
        shuffleButton.setTitle("Simulate changes", for: .normal)
        shuffleButton.addTarget(self, action: #selector(simulateButtonClicked), for: .touchUpInside)
        view.addSubview(shuffleButton)

        segmentedControl = UISegmentedControl(items: ["List", "Grid"])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(styleControlValueChanged), for: .valueChanged)
        view.addSubview(segmentedControl)

        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        contactsPlaceholder = UIView()
        contactsPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contactsPlaceholder)

        // Constraints init
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
            contactsPlaceholder.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 5),
            contactsPlaceholder.bottomAnchor.constraint(equalTo: shuffleButton.topAnchor, constant: 5),
            contactsPlaceholder.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            contactsPlaceholder.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            // Activity indicator constraints
            activityIndicator.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5),
            activityIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5)
        ])
    }



    // MARK: Input handlers
    @objc public func simulateButtonClicked() {

    }

    @objc public func styleControlValueChanged() {
        switch segmentedControl.selectedSegmentIndex {
        case 0: setContactsStyle(.list)
        case 1: setContactsStyle(.grid)
        default: break
        }
    }

    // MARK: Load view
    override func loadView() {
        initUI()

        let context = DataContext(
            contact: MockContactsProvider(),
            gravatar: NetGravatarAPI(simulatedDelay: 0))
        presenter = AllContactsPresenter(
            context: context,
            view: self,
            errorHandler: AlertErrorHandler(parent: self))

        setContactsStyle(.list)
    }
}

// This extension binds collection views data requests to view's presenter
extension AllContactsViewController: ContactsCollectionDataSource {
    func free(ids: [Int]) {
        if let presenter = presenter {
            ids.forEach({ presenter.free(id: $0) })
        }
    }
    
    var contactIds: [Int] {
        return ids ?? []
    }

    func getContactInfo(id: Int, callback: @escaping (ContactViewData?, Bool) -> ()) {
        presenter?.getContactInfo(id: id, callback: callback) ?? callback(nil, false)
    }

    func getAvatarImage(id: Int, callback: @escaping (UIImage?, Bool) -> ()) {
        presenter?.getAvatar(for: id, callback: callback) ?? callback(nil, false)
    }

    func prefetch(ids: [Int]) {
        if let presenter = presenter {
            ids.forEach({ presenter.prefetch(id: $0) })
        }
    }

    func cancelPrefetching(ids: [Int]) {
        if let presenter = presenter {
            ids.forEach({ presenter.cancelPrefetching(id: $0) })
        }
    }
}

extension AllContactsViewController: AllContactsPresenterDelegate {
    func setData(_ data: AllContactsViewData) {
        ids = data.contactsIds
        DispatchQueue.main.async {
            self.contactsView?.reloadData()
        }
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
