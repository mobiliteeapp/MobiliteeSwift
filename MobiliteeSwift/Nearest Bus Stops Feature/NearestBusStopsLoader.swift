//
//  Copyright (c) 2021 Jero Sánchez. All rights reserved.
//

import Foundation

public struct BusStop {
    public let id: Int
    public let latitude: Double
    public let longitude: Double
    public let name: String
    public let address: String
    public let distance: Int
    public let lines: [BusStopLine]
}

public struct BusStopLine {
    public let id: Int
    public let origin: String
    public let destination: String
}

public protocol NearestBusStopsLoader {
    func load(latitude: Double, longitude: Double, radius: Int, completion: (Result<[BusStop], Error>))
}
