//
//  Copyright (c) 2021 Jero Sánchez. All rights reserved.
//

import Foundation

public class RemoteNearestBusStopsLoader {
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result<[NearestBusStop], Error>) -> Void) {
        client.get(from: url) { response in
            switch response {
            case let .success((data, response)):
                if let _ = try? JSONSerialization.jsonObject(with: data), response.statusCode == 200 {
                    completion(.success([]))
                } else {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void)
}
