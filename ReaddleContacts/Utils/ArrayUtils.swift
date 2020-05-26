//
//  ArrayUtils.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 26.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation

public extension Array {
    init(repeating: [Element], count: Int) {
        self.init([[Element]](repeating: repeating, count: count).flatMap { $0 })
    }

    func repeated(count: Int) -> [Element] {
        return [Element](repeating: self, count: count)
    }
}
