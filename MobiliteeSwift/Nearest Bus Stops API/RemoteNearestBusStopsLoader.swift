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
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        client.get(from: url) { response in
            switch response {
            case let .success((data, response)):
                do {
                    let busStops = try NearestBusStopsMapper.map(data, with: response)
                    completion(.success(busStops))
                } catch {
                    if let error = error as? RemoteNearestBusStopsLoader.Error {
                        completion(.failure(error))
                    }
                }
                
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

private final class NearestBusStopsMapper {
    private struct Root: Decodable {
        let code: String
        let data: [Stop]
    }

    private struct Stop: Decodable {
    }
        
    private static var OK_200: Int { return 200 }

    private static var successCode: String { return "00" }
    private static var sessionExpiredCode: String { return "80" }

    static func map(_ data: Data, with response: HTTPURLResponse) throws -> [NearestBusStop] {
        guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteNearestBusStopsLoader.Error.invalidData
        }
        
        if root.code == NearestBusStopsMapper.successCode {
            return []
            
        } else if root.code == NearestBusStopsMapper.sessionExpiredCode {
            throw RemoteNearestBusStopsLoader.Error.sessionExpired
            
        } else {
            throw RemoteNearestBusStopsLoader.Error.invalidData
        }
    }
}
