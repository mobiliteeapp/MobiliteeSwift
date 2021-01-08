//
//  Copyright (c) 2021 Jero Sánchez. All rights reserved.
//

import XCTest

class RemoteNearestBusStopsLoader {
    private let url: URL
    private let client: HTTPClient
    
    enum Error: Swift.Error {
        case connectivity
    }
    
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func load(completion: @escaping (Error?) -> Void) {
        client.get(from: url) { _ in
            completion(.connectivity)
        }
    }
}

class HTTPClient {
    var requestedURLs = [URL]()
    private var completions = [(Error?) -> Void]()
    
    func get(from url: URL, completion: @escaping (Error?) -> Void) {
        requestedURLs.append(url)
        completions.append(completion)
    }
    
    func completeWithError(_ error: Error, at index: Int = 0) {
        completions[index](error)
    }
}

class LoadNearestBusStopsFromRemoteUseCaseTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://any-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load() { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        let clientError = NSError(domain: "a client error", code: 42)
        
        let exp = expectation(description: "Wait for load completion")
        
        var receivedError: RemoteNearestBusStopsLoader.Error?
        sut.load() { error in
            receivedError = error
            exp.fulfill()
        }
        
        client.completeWithError(clientError)
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(receivedError, .connectivity)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://any-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteNearestBusStopsLoader, client: HTTPClient) {
        let client = HTTPClient()
        let sut = RemoteNearestBusStopsLoader(url: url, client: client)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        
        return (sut, client)
    }
    
    private func trackForMemoryLeaks(_ object: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}
