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
}

public struct NearestBusStopLine: Equatable {
    public let id: Int
    public let origin: String
    public let destination: String
}
