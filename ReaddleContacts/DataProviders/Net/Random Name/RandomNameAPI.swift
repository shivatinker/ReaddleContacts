//
//  RandomNameAPI.swift
//  ReaddleContacts
//
//  Created by Andrii Zinoviev on 30.05.2020.
//  Copyright © 2020 Andrii Zinoviev. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

/// Class for requests to `randomuser.me`
public class RandomNameAPI {
    private static let API_URL = URL(string: "https://randomuser.me/api")!
    private let taskQueue = DispatchQueue(label: "com.shivatinker.contacts.randomname")

    public struct RandomInfo {
        let firstName: String
        let lastName: String
        let email: String
    }

    private struct NameJSON: Codable {
        let first: String
        let last: String
    }

    private struct ResultJSON: Codable {
        let name: NameJSON
        let email: String
    }

    private struct ResponseJSON: Codable {
        let results: [ResultJSON]
    }
    
    /// Gets random names and emails
    /// - Parameter count: Random info objects count
    /// - Returns: Promise
    public func getRandomNames(count: Int) -> Promise<[RandomInfo]> {
        Promise { seal in
            taskQueue.async {
                let params: Parameters = ["results": "\(count)", "nat": "us,fr,es,ch"]
                AF.request(Self.API_URL, parameters: params)
                    .responseDecodable(of: ResponseJSON.self, queue: self.taskQueue) { (response) in
                        switch response.result {
                        case .success(let r):
                            seal.fulfill(r.results.map { RandomInfo(firstName: $0.name.first,
                                                                    lastName: $0.name.last,
                                                                    email: $0.email) })
                        case .failure(let e):
                            seal.reject(NetError.fromAFError(e))
                        }
                }
            }
        }
    }
}
