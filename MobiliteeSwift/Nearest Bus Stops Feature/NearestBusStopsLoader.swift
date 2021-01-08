//
//  Copyright (c) 2021 Jero Sánchez. All rights reserved.
//

import Foundation

public protocol NearestBusStopsLoader {
    func load(latitude: Double, longitude: Double, radius: Int, completion: (Result<[NearestBusStop], Error>))
}
