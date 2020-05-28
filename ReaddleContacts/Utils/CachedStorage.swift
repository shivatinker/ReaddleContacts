//
//  CachedStorage.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 27.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation

/// Storage that supports automatic caching objects from provider
public class CachedStorage<I: Hashable, T> {
    public typealias Provider = (I, @escaping ((T?) -> Void)) -> Void
    public typealias Callback = (T?, Bool) -> Void

    // MARK: Private members
    private var storage = [I: T]()
    private var isLoading = [I: Bool]()

    private let queue = DispatchQueue(label: "Cached storage")
    private var pendingCallbacks = [I: [Callback]]()
    private var cachedIDs = [I]()
    private let maxCount: Int?

    private let provider: Provider

    // Loads item and executes callbacks
    private func load_(_ key: I) {
        // If item is not loading, load it from provider and execute all
        // pending callbacks, that ensures that item will be loaded only ONCE
        if !(self.isLoading[key] ?? false) {
            self.isLoading[key] = true

            // Load item from provider
            self.provider(key) { item in
                self.queue.async {
                    if let item = item {
                        if self.storage[key] == nil {
                            // If there are already maximum cached items, remove item, that was accesed longest time ago
                            if let c = self.maxCount,
                                self.storage.count == c {
                                self.remove_(self.cachedIDs.removeFirst())
                            }
                            if !self.cachedIDs.contains(key) {
                                self.cachedIDs.append(key)
                            }
                        }

                        self.storage[key] = item
                    }
                    self.pendingCallbacks[key]?.forEach({ $0(item, true) })
                    self.pendingCallbacks[key]?.removeAll()
                    self.isLoading[key] = false
                }
            }
        }
    }

    private func get_(_ key: I, _ callback: @escaping Callback) {
        if let item = self.storage[key] {
            // If item is cached, immediatly return it and mark it as relevant
            let c = self.cachedIDs.count
            self.cachedIDs.removeAll(where: { $0 == key })
            self.cachedIDs.append(key)
            assert(c == self.cachedIDs.count)
            callback(item, false)
        } else {
            // Attach callback to pendingCallbacks of item
            if self.pendingCallbacks[key] != nil {
                self.pendingCallbacks[key]!.append(callback)
            } else {
                self.pendingCallbacks[key] = [callback]
            }

            self.load_(key)
        }
    }

    private func remove_(_ key: I) {
        self.cachedIDs.removeAll(where: { $0 == key })
        self.storage[key] = nil
        self.isLoading[key] = nil
        self.pendingCallbacks[key] = nil
    }

    // MARK: Public API
    /// Initiates empty storage with given provider
    /// - Parameter provider: provider closure that will be callsed, when new object requested
    public init(maxCount: Int? = nil, provider: @escaping Provider) {
        self.provider = provider
        self.maxCount = maxCount
    }

    /// Gets item from cache or loads it from provider
    /// - Parameters:
    ///   - key: item key
    ///   - callback: callback to be called when item is loaded
    public func get(_ key: I, _ callback: @escaping Callback) {
        queue.async {
            self.get_(key, callback)
        }
    }

    /// Loads item from provider
    /// - Parameters:
    ///   - key: item key
    ///   - forced: if true, load new item even if it is cached
    public func load(_ key: I, forced: Bool = false) {
        queue.async {
            if self.storage[key] == nil || forced {
                self.load_(key)
            }
        }
    }

    /// Removes item from cache
    /// - Parameter key: item key
    public func remove(_ key: I) {
        queue.async {
            self.remove_(key)
        }
    }

    /// Clears all cached items
    public func removeAll() {
        queue.async {
            self.cachedIDs.removeAll()
            self.storage.removeAll()
            self.isLoading.removeAll()
            self.pendingCallbacks.removeAll()
        }
    }
}
