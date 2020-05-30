//
//  ViewController.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import UIKit

class AllContactsViewController: UIViewController {

    internal var presenter: AllContactsPresenter
    private var dataContext: DataContext

    /// Contact IDs to display
    private var ids: [Int]?

    // MARK: UI
    private var shuffleButton: UIButton!
    private var activityIndicator: UIActivityIndicatorView!
    private var helpLabel: UILabel!

    private let toSingleViewTransition = AllToSingleViewAnimator()
    private let toAllViewTransition = SingleToAllViewTransition()

    /// Current contacts display view, for now it can be table or collection
    private(set) var contactsContainer: ContactsViewContainer = ContactsViewContainer()

    private func initUI() {
        // UI Init
        title = "Contacts"

        view = UIView()
        view.backgroundColor = .systemBackground

        shuffleButton = UIButton(type: .system)
        shuffleButton.translatesAutoresizingMaskIntoConstraints = false
        shuffleButton.setTitle("Simulate changes", for: .normal)
        shuffleButton.addTarget(self, action: #selector(simulateButtonClicked), for: .touchUpInside)
        view.addSubview(shuffleButton)

        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)

        contactsContainer.translatesAutoresizingMaskIntoConstraints = false
        contactsContainer.accessibilityIdentifier = "ContactsPlaceholder"
        view.addSubview(contactsContainer)

        helpLabel = UILabel()
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        helpLabel.numberOfLines = 0
        helpLabel.text = "Use swipe gestures to toggle view mode\n Created by Andrii Zinoviev"
        view.addSubview(helpLabel)

        // Constraints init
        NSLayoutConstraint.activate([
            // Button constraints
            shuffleButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            shuffleButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            shuffleButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            shuffleButton.heightAnchor.constraint(equalToConstant: 60),
            // Table constraints
            contactsContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            contactsContainer.bottomAnchor.constraint(equalTo: helpLabel.topAnchor, constant: -5),
            contactsContainer.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            contactsContainer.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            // Label constraints
            helpLabel.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            helpLabel.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            helpLabel.bottomAnchor.constraint(equalTo: shuffleButton.topAnchor, constant: -5)
//            helpLabel.heightAnchor.constraint(equalToConstant: 60)

        ])
    }

    // MARK: Input handlers
    @objc public func simulateButtonClicked() {
        presenter.onSimulateChangesClicked()
    }

    public init(dataContext: DataContext) {
        self.presenter = AllContactsPresenter(context: dataContext)
        self.dataContext = dataContext
        super.init(nibName: nil, bundle: nil)
        presenter.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        navigationController?.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Load view
    override func loadView() {
        initUI()

        let table = ContactsTableView()
        table.contactsDelegate = self

        let collection = ContactsCollectionView()
        collection.contactsDelegate = self

        contactsContainer.contactViews = [table, collection]

        contactsContainer.setView(index: 0)
        presenter.update()
    }
}

// MARK: Delegates
// This extension binds collection views data requests to view's presenter
extension AllContactsViewController: ContactsCollectionDelegate {
    func onContactSelected(id: Int) {
        presenter.onContactSelected(id: id)
    }

    var contactIds: [Int] {
        return ids ?? []
    }

    func getContactInfo(id: Int, callback: @escaping (ContactViewData?, Bool) -> Void) {
        presenter.getContactInfo(id: id, callback: callback)
    }

    func getAvatarImage(id: Int, callback: @escaping (UIImage?, Bool) -> Void) {
        presenter.getAvatar(for: id, callback: callback)
    }

    func prefetch(ids: [Int]) {
        ids.forEach({ presenter.prefetch(id: $0) })
    }

    func cancelPrefetching(ids: [Int]) {
        ids.forEach({ presenter.cancelPrefetching(id: $0) })
    }
}

extension AllContactsViewController: AllContactsPresenterDelegate {
    func showContactInfo(id: Int) {
        DispatchQueue.main.async {
            guard let navController = self.navigationController else {
                fatalError("No navigation controller provided")
            }
            let newController = SingleContactViewController(
                contactId: id,
                dataContext: self.dataContext)
//            self.present(newController, animated: true, completion: nil)
            navController.pushViewController(newController, animated: true)
        }
    }

    func setData(_ data: AllContactsViewData) {
        ids = data.contactsIds
        DispatchQueue.main.async {
            self.contactsContainer.currentView?.reloadData()
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

extension AllContactsViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            return toSingleViewTransition
        } else {
            return toAllViewTransition
        }
    }
}
