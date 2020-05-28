//
//  NetGravatarAPI.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 25.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireImage

import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG

private extension NetGravatarAPI {
    /// Generates MD5 hex hash string from data
    /// - Parameter messageData: data
    /// - Returns: String with hex representation of md5 hash
    static func MD5(messageData: Data) -> String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digestData = Data(count: length)

        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        let md5Hex = digestData.map { String(format: "%02hhx", $0) }.joined()
        return md5Hex
    }
}

/// Gravatar API implementation with real API
public class NetGravatarAPI: GravatarAPI {
    private static let API_URL = URL(string: "https://www.gravatar.com/avatar")!

    private let delay: TimeInterval
    public init(simulatedDelay: TimeInterval = 0) {
        delay = simulatedDelay
    }

    private let afSession = Session(startRequestsImmediately: false)
    private var taskQueue = DispatchQueue(label: "Gravatar API")

    private var currentTasks = [Int: DataRequest]()

    public func getAvatarImage(_ params: GravatarRequest, callback: @escaping GravatarCallback) {
        taskQueue.asyncAfter(deadline: .now() + delay) {
            // Create email hash according to https://ru.gravatar.com/site/implement/images/
            guard let data = params.email.trimmingCharacters(in: [" "]).lowercased().data(using: .utf8) else {
                callback(.failure(error: .unknown("Failed to convert email to data")))
                return
            }
            let md5 = Self.MD5(messageData: data)

            let httpparams: Parameters = [
                "s": params.size,
                "d": params.defaultAvatar.queryString,
            ]

            let request = self.afSession.request(Self.API_URL.appendingPathComponent(md5), parameters: httpparams)
                .responseImage { (response) in
                    defer {
                        self.taskQueue.sync {
                            self.currentTasks[params.taskId] = nil
                        }
                    }

                    switch response.result {
                    case .failure(let failure):
                        // Check if request got cancelled
                        if case AFError.explicitlyCancelled = failure {
                            callback(.failure(error: .requestCancelled("Request cancelled")))
                            return
                        }

                        // Check if we expect 404 on missing avatars, so we dont produce NetError
                        if params.defaultAvatar == .error,
                            case let AFError.responseValidationFailed(reason: reason) = failure,
                            case .unacceptableContentType = reason {
                            callback(.success(result: nil))
                            return
                        }

                        // Here he have problems
                        debugPrint(failure)
                        callback(.failure(error: NetError.fromAFError(failure)))
                    case .success(let image):
                        callback(.success(result: image))
                    }
            }
            self.currentTasks[params.taskId] = request
            
            request.resume()
        }
    }


    public func cancelLoading(taskId: Int) {
        taskQueue.async {
//            print("avatar \(taskId) req cancel")
            if let request = self.currentTasks[taskId] {
                if request.isResumed {
                    request.cancel()
                }
            }
        }
    }
}
