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
    public typealias Provider = (I, @escaping ((T?) -> ())) -> ()
    public typealias Callback = (T?, Bool) -> ()

    // MARK: Private members
    private var storage = [I: T]()
    private var isLoading = [I: Bool]()

    private let pcSemaphore = DispatchSemaphore(value: 1)
    private let lQueue = DispatchQueue(label: "Cached storage")
    private var pendingCallbacks = [I: [Callback]]()

    private let provider: Provider

    private func synchronized<R>(_ f: () -> (R)) -> R {
        pcSemaphore.wait()
        defer { pcSemaphore.signal() }
        return f()
    }

    // Loads item and executes callbacks
    private func load_(_ key: I) {
        // If item is not loading, load it from provider and execute all pending callbacks, that ensures that item will be loaded only ONCE
        if !(synchronized({ isLoading[key] }) ?? false) {
            synchronized({ isLoading[key] = true })

            // Load item from provider
            provider(key) { item in
                // Lock pendingCallbacks dictionary while executing callbacks
                self.synchronized {
                    self.storage[key] = item
                    self.pendingCallbacks[key]?.forEach({ $0(item, true) })
                    self.pendingCallbacks[key]?.removeAll()
                    self.isLoading[key] = false
                }
            }
        }
    }

    private func get_(_ key: I, _ callback: @escaping Callback) {
        if let item = synchronized({ storage[key] }) {
            // If item is cached, immediatly return it
            callback(item, false)
        } else {
            // Attach callback to pendingCallbacks of item

            // Wait till all callbacks will be executed, so we can modify pendingCallbacks
            // Not doing it will lead in possible modify-while-read bug
            synchronized {
                if pendingCallbacks[key] != nil {
                    pendingCallbacks[key]!.append(callback)
                } else {
                    pendingCallbacks[key] = [callback]
                }
            }

            load_(key)
        }
    }

    // MARK: Public API
    /// Initiates empty storage with given provider
    /// - Parameter provider: provider closure that will be callsed, when new object requested
    public init(provider: @escaping Provider) {
        self.provider = provider
    }

    /// Gets item from cache or loads it from provider
    /// - Parameters:
    ///   - key: item key
    ///   - callback: callback to be called when item is loaded
    public func get(_ key: I, _ callback: @escaping Callback) {
        lQueue.async {
            self.get_(key, callback)
        }
    }

    /// Loads item from provider
    /// - Parameters:
    ///   - key: item key
    ///   - forced: if true, load new item even if it is cached
    public func load(_ key: I, forced: Bool = false) {
        lQueue.async {
            if self.synchronized({ self.storage[key] }) == nil || forced {
                self.load_(key)
            }
        }
    }

    /// Removes item from cache
    /// - Parameter key: item key
    public func remove(_ key: I) {
        lQueue.async {
            self.synchronized {
                self.storage[key] = nil
                self.isLoading[key] = nil
                self.pendingCallbacks[key] = nil
            }
        }
    }

    /// Clears all cached items
    public func removeAll() {
        lQueue.async {
            self.synchronized {
                self.storage.removeAll()
                self.isLoading.removeAll()
                self.pendingCallbacks.removeAll()
            }
        }
    }
}
