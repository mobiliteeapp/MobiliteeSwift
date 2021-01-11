//
//  Copyright (c) 2021 Jero Sánchez. All rights reserved.
//

import Foundation

final class NearestBusStopsMapper {
    private struct Root: Decodable {
        let code: String
        let data: [RemoteNearestBusStop]
    }
        
    private static var OK_200: Int { return 200 }

    private static var successCode: String { return "00" }
    private static var sessionExpiredCode: String { return "80" }

    static func map(_ data: Data, with response: HTTPURLResponse) throws -> [RemoteNearestBusStop] {
        guard response.statusCode == OK_200, let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteNearestBusStopsLoader.Error.invalidData
        }
        
        if root.code == NearestBusStopsMapper.successCode {
            return root.data
            
        } else if root.code == NearestBusStopsMapper.sessionExpiredCode {
            throw RemoteNearestBusStopsLoader.Error.sessionExpired
            
        } else {
            throw RemoteNearestBusStopsLoader.Error.invalidData
        }
    }
}

struct RemoteNearestBusStop: Decodable {
    let stopId: Int
    let geometry: Geometry
    let stopName: String
    let address: String
    let metersToPoint: Int
    let lines: [RemoteNearestBusStopLine]
    
    var nearestBusStop: NearestBusStop {
        let nearestBusStopline = lines.map { $0.nearestBusStopline }
        return NearestBusStop(
            id: stopId,
            latitude: geometry.coordinates[1],
            longitude: geometry.coordinates[0],
            name: stopName,
            address: address,
            distance: metersToPoint,
            lines: nearestBusStopline)
    }
}

struct Geometry: Decodable {
    let coordinates: [Double]
}

struct RemoteNearestBusStopLine: Decodable {
    let line: String
    let nameA: String
    let nameB: String
    
    var nearestBusStopline: NearestBusStopLine {
        return NearestBusStopLine(id: line, origin: nameA, destination: nameB)
    }
}
