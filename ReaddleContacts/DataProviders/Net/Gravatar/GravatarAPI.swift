//
//  GravatarAPI.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import AlamofireImage
import PromiseKit

/// Wrapper object for gravatar parameters
public struct GravatarParams {

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
    public let taskId: Int
    public let defaultAvatar: DefaultAvatar

    public init(taskId: Int, size: Int = 50, defaultAvatar: DefaultAvatar = .identicon) {
        self.size = size
        self.defaultAvatar = defaultAvatar
        self.taskId = taskId
    }
}

/// Gravatar API, that supports basic user avatar operations
public protocol GravatarAPI {
    /// Asynchroniusly get user avatar from email
    /// - Parameters:
    ///   - params: Request parameters
    ///   - callback: Callback to be called
    func getAvatarImage(email: String, params: GravatarParams) -> Promise<UIImage?>

    /// Requests cancelling loading of avatar
    /// - Parameter taskId: taskId, given to parameters of request to cancel
    func cancelLoading(taskId: Int)
}
