//
//  Copyright (c) 2021 Jero Sánchez. All rights reserved.
//

import XCTest
import MobiliteeSwift

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
        
        expect(sut, toCompleteWithError: .connectivity, when: {
            client.completeWithError(clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()

        let samples = [199, 201, 300, 400, 500].enumerated()
        
        samples.forEach { index, code in
            expect(sut, toCompleteWithError: .invalidData, when: {
                client.completeSuccessfully(withStatusCode: code, data: Data(), at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithError: .invalidData, when: {
            let invalidJSON = "invalid JSON".data(using: .utf8)!
            client.completeSuccessfully(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    func test_load_deliversEmptyResultOn200HTTPResponseWithEmptyJSONAndCode00() {
        let (sut, client) = makeSUT()

        let exp = expectation(description: "Wait for load completion")

        sut.load() { result in
            switch result {
            case let .success(busStops):
                XCTAssertEqual(busStops, [])

            case .failure:
                XCTFail("Expected successful empty result, got failure instead")
            }

            exp.fulfill()
        }

        let emptyJSON: [String: Any] = [
            "code": "00",
            "data": []
        ]
        let data = try! JSONSerialization.data(withJSONObject: emptyJSON)

        client.completeSuccessfully(withStatusCode: 200, data: data)

        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://any-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteNearestBusStopsLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
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
    
    private func expect(_ sut: RemoteNearestBusStopsLoader, toCompleteWithError expectedError: RemoteNearestBusStopsLoader.Error, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")

        sut.load() { result in
            switch result {
            case let .failure(receivedError):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
                
            case .success:
                XCTFail("Expected failure with error \(expectedError), got success result instead", file: file, line: line)
            }

            exp.fulfill()
        }

        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (Result<(Data, HTTPURLResponse), Error>) -> Void)]()

        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }

        func get(from url: URL, completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void) {
            messages.append((url, completion))
        }
        
        func completeWithError(_ error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func completeSuccessfully(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success((data, response)))
        }
    }
}
