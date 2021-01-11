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
