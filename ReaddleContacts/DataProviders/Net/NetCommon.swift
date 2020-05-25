//
//  NetCommon.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import Alamofire

/// Represents error in network query
public enum NetError: Error {
    case connectionError(_ description: String)
    case unknown(_ description: String)

    public static func fromAFError(_ e: AFError) -> NetError {
        return connectionError(e.localizedDescription)
    }
}

extension NetError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .connectionError(let description): return "Connection error: \(description)"
        case .unknown(let description): return "Unknown error: \(description)"
        }
    }
}
