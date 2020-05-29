//
//  ViewController.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import UIKit

class AllContactsViewController: UIViewController {

    private var presenter: AllContactsPresenter
    private var dataContext: DataContext

    /// Contact IDs to display
    private var ids: [Int]?

    // MARK: UI
    private var segmentedControl: UISegmentedControl!
    private var shuffleButton: UIButton!
    private var activityIndicator: UIActivityIndicatorView!

    private let toSingleViewTransition = AllToSingleViewAnimator()

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

        segmentedControl = UISegmentedControl(items: ["List", "Grid"])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(styleControlValueChanged), for: .valueChanged)
        view.addSubview(segmentedControl)

        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)

        contactsContainer.translatesAutoresizingMaskIntoConstraints = false
        contactsContainer.accessibilityIdentifier = "ContactsPlaceholder"
        view.addSubview(contactsContainer)

        // Constraints init
        NSLayoutConstraint.activate([
            // Button constraints
            shuffleButton.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            shuffleButton.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            shuffleButton.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            shuffleButton.heightAnchor.constraint(equalToConstant: 60),
            // Seg constraints
            segmentedControl.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            segmentedControl.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor, constant: 50),
            segmentedControl.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor, constant: -50),
            segmentedControl.heightAnchor.constraint(equalToConstant: 30),
            // Table constraints
            contactsContainer.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 5),
            contactsContainer.bottomAnchor.constraint(equalTo: shuffleButton.topAnchor, constant: 5),
            contactsContainer.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            contactsContainer.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            // Activity indicator constraints
            activityIndicator.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -5),
            activityIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5)
        ])
    }

    // MARK: Input handlers
    @objc public func simulateButtonClicked() {

    }

    @objc public func styleControlValueChanged() {
        contactsContainer.setView(index: segmentedControl.selectedSegmentIndex)
    }

    public init(dataContext: DataContext) {
        self.presenter = AllContactsPresenter(context: dataContext)
        self.dataContext = dataContext
        super.init(nibName: nil, bundle: nil)
        presenter.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        navigationController?.delegate = self
        presenter.update()
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
        return toSingleViewTransition
    }
}
