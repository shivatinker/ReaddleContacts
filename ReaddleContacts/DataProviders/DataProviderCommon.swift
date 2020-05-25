//
//  DataProviderCommon.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation

public typealias ConditionalCallback<T, E> = (ConditionalResult<T, E>) -> ()

public enum ConditionalResult<T, E> {
    case success(result: T)
    case failure(error: E)
}
