//
//  Copyright (c) 2021 Jero Sánchez. All rights reserved.
//

import Foundation

public class RemoteNearestBusStopsLoader {
    private let url: URL
    private let client: HTTPClient
    
    public struct RequestParams {
        public let latitude: Double
        public let longitude: Double
        public let radius: Int
        
        public init(latitude: Double, longitude: Double, radius: Int) {
            self.latitude = latitude
            self.longitude = longitude
            self.radius = radius
        }
    }
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
        case sessionExpired
    }
    
    public typealias LoadResult = Result<[NearestBusStop], Swift.Error>
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(requestParams: RequestParams, completion: @escaping (LoadResult) -> Void) {
        let endpointURL = url
            .appendingPathComponent("\(requestParams.longitude)")
            .appendingPathComponent("\(requestParams.latitude)")
            .appendingPathComponent("\(requestParams.radius)")

        client.get(from: endpointURL) { [weak self] response in
            guard self != nil else { return }
            
            switch response {
            case let .success((data, response)):
                completion(RemoteNearestBusStopsLoader.map(data, with: response))
                
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
    
    // MARK: - Helpers
    
    private static func map(_ data: Data, with response: HTTPURLResponse) -> LoadResult {
        do {
            let busStops = try NearestBusStopsMapper.map(data, with: response)
            return .success(busStops.toModel())
        } catch {
            return .failure(error)
        }
    }
}

private extension RemoteNearestBusStop {
    func toModel() -> NearestBusStop {
        return NearestBusStop(
            id: stopId,
            latitude: geometry.coordinates[1],
            longitude: geometry.coordinates[0],
            name: stopName,
            address: address,
            distance: metersToPoint,
            lines: lines.toModel())
    }
}

private extension Array where Element == RemoteNearestBusStop {
    func toModel() -> [NearestBusStop] {
        self.map { $0.toModel() }
    }
}

private extension RemoteNearestBusStopLine {
    func toModel() -> NearestBusStopLine {
        return NearestBusStopLine(id: line, origin: nameA, destination: nameB)
    }
}

private extension Array where Element == RemoteNearestBusStopLine {
    func toModel() -> [NearestBusStopLine] {
        self.map { $0.toModel() }
    }
}
