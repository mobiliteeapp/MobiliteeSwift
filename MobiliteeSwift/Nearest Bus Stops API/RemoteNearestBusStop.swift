//
//  Copyright (c) 2021 Jero Sánchez. All rights reserved.
//

import Foundation

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
