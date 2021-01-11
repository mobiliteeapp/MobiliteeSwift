//
//  Copyright (c) 2021 Jero Sánchez. All rights reserved.
//

import Foundation

public struct NearestBusStop: Equatable {
    public let id: Int
    public let latitude: Double
    public let longitude: Double
    public let name: String
    public let address: String
    public let distance: Int
    public let lines: [NearestBusStopLine]
    
    public init(id: Int, latitude: Double, longitude: Double, name: String, address: String, distance: Int, lines: [NearestBusStopLine]) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.address = address
        self.distance = distance
        self.lines = lines
    }
}

public struct NearestBusStopLine: Equatable {
    public let id: String
    public let origin: String
    public let destination: String
    
    public init(id: String, origin: String, destination: String) {
        self.id = id
        self.origin = origin
        self.destination = destination
    }
}
