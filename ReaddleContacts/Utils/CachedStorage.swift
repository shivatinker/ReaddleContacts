//
//  CachedStorage.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 27.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation

public class CachedStorage<I: Hashable, T> {
    public typealias Provider = (I, ((T) -> ())) -> ()

    private var storage = [I: T]()
    private let provider: Provider

    public init(provider: @escaping Provider) {
        self.provider = provider
    }

    public func get(_ key: I, _ callback: (T, Bool) -> ()) {
        if let item = storage[key] {
            callback(item, false)
        } else {
            provider(key) { item in
                self.storage[key] = item
                callback(item, true)
            }
        }
    }
}
