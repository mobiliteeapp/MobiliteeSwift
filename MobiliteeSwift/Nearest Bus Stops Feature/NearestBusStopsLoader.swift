//
//  Copyright (c) 2021 Jero Sánchez. All rights reserved.
//

import Foundation

public typealias LoadNearestBusStopsResult = Result<[NearestBusStop], Error>

public protocol NearestBusStopsLoader {
    func load(latitude: Double, longitude: Double, radius: Int, completion: (LoadNearestBusStopsResult))
}
