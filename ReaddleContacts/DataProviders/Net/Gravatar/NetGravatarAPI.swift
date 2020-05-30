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
import PromiseKit

private extension NetGravatarAPI {

}

/// Gravatar API implementation with real API
public class NetGravatarAPI: GravatarAPI {
    private static let API_URL = URL(string: "https://www.gravatar.com/avatar")!

    private let delay: TimeInterval
    public init(simulatedDelay: TimeInterval = 0) {
        delay = simulatedDelay
    }

    private let afSession = Session(startRequestsImmediately: false)
    private var queue = DispatchQueue(label: "com.shivatinker.contacts.gravatar")

    private var currentTasks = [Int: DataRequest]()

    public func getAvatarImage(email: String, params: GravatarParams) -> Promise<UIImage?> {
        Promise<UIImage?> { seal in
            queue.async {
                // Create email hash according to https://ru.gravatar.com/site/implement/images/
                let md5 = email.trimmingCharacters(in: [" "]).lowercased().md5()
                let httpparams: Parameters = [
                    "s": params.size,
                    "d": params.defaultAvatar.queryString
                ]

                let request = self.afSession.request(Self.API_URL.appendingPathComponent(md5), parameters: httpparams)
                    .responseImage { (response) in
                        switch response.result {
                        case .failure(let failure):
                            // Check if request got cancelled
                            if case AFError.explicitlyCancelled = failure {
                                seal.reject(PMKError.cancelled)
                                return
                            }

                            // Check if we expect 404 on missing avatars, so we dont produce errors
                            if params.defaultAvatar == .error,
                                case let AFError.responseValidationFailed(reason: reason) = failure,
                                case .unacceptableContentType = reason {
                                seal.fulfill(nil)
                                return
                            }

                            // Here he have problems
                            seal.reject(failure)
                        case .success(let image):
                            seal.fulfill(image)
                        }
                }

                // Start request
                self.currentTasks[params.taskId] = request
                request.resume()
            }
        }.ensure(on: queue) {
            self.currentTasks[params.taskId] = nil
        }
    }

    public func cancelLoading(taskId: Int) {
        queue.async {
            if let request = self.currentTasks[taskId] {
                if request.isResumed {
                    request.cancel()
                }
            }
        }
    }
}
