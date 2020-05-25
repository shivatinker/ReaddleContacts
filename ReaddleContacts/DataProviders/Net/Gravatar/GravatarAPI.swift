//
//  GravatarAPI.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import AlamofireImage

/// Wrapper object for gravatar parameters
public struct GravatarRequest {

    public enum DefaultAvatar {
        case error
        case identicon
        case retro

        public var queryString: String {
            switch self {
            case .error: return "404"
            case .identicon: return "identicon"
            case .retro: return "retro"
            }
        }
    }

    public let size: Int
    public let email: String
    public let defaultAvatar: DefaultAvatar = .identicon


    public init(email: String, size: Int = 200) {
        self.email = email
        self.size = size
    }
}

/// Gravatar API, that supports basic user avatar operations
public protocol GravatarAPI {
    typealias GravatarCallback = (ConditionalResult<Image, NetError>) -> ()
    /// Asynchroniusly get user avatar from email
    /// - Parameters:
    ///   - params: Request parameters
    ///   - callback: Callback to be called
    func getAvatarImage(_ params: GravatarRequest,
                        callback: @escaping GravatarCallback)
}
