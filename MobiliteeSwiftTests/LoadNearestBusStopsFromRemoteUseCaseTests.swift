//
//  Copyright (c) 2021 Jero Sánchez. All rights reserved.
//

import XCTest

class RemoteNearestBusStopsLoader {
    private let url: URL
    private let client: HTTPClient
    
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func load() {
        client.get(from: url)
    }
}

class HTTPClient {
    var requestedURLs = [URL]()
    
    func get(from url: URL) {
        requestedURLs.append(url)
    }
}

class LoadNearestBusStopsFromRemoteUseCaseTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let url = URL(string: "https://any-url.com")!
        let client = HTTPClient()
        
        _ = RemoteNearestBusStopsLoader(url: url, client: client)
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://any-url.com")!
        let client = HTTPClient()
        let sut = RemoteNearestBusStopsLoader(url: url, client: client)
        
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
}
