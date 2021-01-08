//
//  Copyright (c) 2021 Jero Sánchez. All rights reserved.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void)
}

public class RemoteNearestBusStopsLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
        case sessionExpired
    }
    
    public typealias LoadResult = Result<[NearestBusStop], Error>
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    private static var OK_200: Int { return 200 }
    
    private static var successCode: String { return "00" }
    private static var sessionExpiredCode: String { return "80" }

    public func load(completion: @escaping (LoadResult) -> Void) {
        client.get(from: url) { response in
            switch response {
            case let .success((data, response)):
                if let root = try? JSONDecoder().decode(Root.self, from: data), response.statusCode == RemoteNearestBusStopsLoader.OK_200 {
                    if root.code == RemoteNearestBusStopsLoader.successCode {
                        completion(.success([]))
                    } else if root.code == RemoteNearestBusStopsLoader.sessionExpiredCode {
                        completion(.failure(.sessionExpired))
                    } else {
                        completion(.failure(.invalidData))
                    }
                    
                } else {
                    completion(.failure(.invalidData))
                }
                
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

private struct Root: Decodable {
    let code: String
    let data: [Stop]
}

private struct Stop: Decodable {
}
