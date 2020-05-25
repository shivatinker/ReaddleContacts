//
//  DataProviderCommon.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation

public protocol ErrorHandler {
    func error(_ e: Error)
}

public enum ConditionalResult<T, E: Error> {
    case success(result: T)
    case failure(error: E)
    
    /// Unwraps result
    /// If result is success returns unwrapped result object
    /// If result is failure passes an error to errorHandler and returns nil
    /// - Parameter errorHandler: ErrorHandler to handle failure case
    /// - Returns: Optional T value
    public func unwrap(errorHandler: ErrorHandler? = nil) -> T? {
        switch self {
        case .failure(let error): errorHandler?.error(error)
        case .success(let result): return result
        }
        return nil
    }
}

public struct DataContext {
    public let contact: ContactsProvider
    public let gravatar: GravatarAPI
}
