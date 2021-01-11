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
        
        expect(sut, toCompleteWith: .failure(RemoteNearestBusStopsLoader.Error.connectivity), when: {
            client.completeWithError(clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()

        let samples = [199, 201, 300, 400, 500].enumerated()
        
        samples.forEach { index, code in
            expect(sut, toCompleteWith: .failure(RemoteNearestBusStopsLoader.Error.invalidData), when: {
                client.complete(withStatusCode: code, data: emptyJSONWithSuccessCode(), at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(RemoteNearestBusStopsLoader.Error.invalidData), when: {
            let invalidJSON = "invalid JSON".data(using: .utf8)!
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    func test_load_deliversInvalidDataErrorOn200HTTPResponseWithAnyUnknownCode() {
        let (sut, client) = makeSUT()

        let samples = ["", " ", "AZ"].enumerated()
        
        samples.forEach { index, code in
            expect(sut, toCompleteWith: .failure(RemoteNearestBusStopsLoader.Error.invalidData), when: {
                client.complete(withStatusCode: 200, data: emptyJSON(withCode: code), at: index)
            })
        }
    }
    
    func test_load_deliversSessionExpiredErrorOn200HTTPResponseWithSessionExpiredCode() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .failure(RemoteNearestBusStopsLoader.Error.sessionExpired), when: {
            client.complete(withStatusCode: 200, data: emptyJSONWithSessionExpiredCode())
        })
    }
    
    func test_load_deliversNoBusStopsOn200HTTPResponseWithSuccessCodeAndEmptyJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .success([]), when: {
            client.complete(withStatusCode: 200, data: emptyJSONWithSuccessCode())
        })
    }
    
    func test_load_deliversBusStopsOn200HTTPResponseWithSuccessCodeAndJSONList() {
        let (sut, client) = makeSUT()
        
        let stop1 = makeBusStop(id: 1)
        let stop2 = makeBusStop(id: 2)

        let busStops = [stop1.model, stop2.model]
        let busStopsJSON: [String: Any] = [
            "code": "00",
            "data": [
                stop1.json, stop2.json
            ]
        ]
        
        expect(sut, toCompleteWith: .success(busStops), when: {
            let jsonData = try! JSONSerialization.data(withJSONObject: busStopsJSON)
            client.complete(withStatusCode: 200, data: jsonData)
        })
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://any-url.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteNearestBusStopsLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteNearestBusStopsLoader(url: url, client: client)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        
        return (sut, client)
    }
    
    private func emptyJSONWithSuccessCode() -> Data {
        return emptyJSON(withCode: "00")
    }
    
    private func emptyJSONWithSessionExpiredCode() -> Data {
        return emptyJSON(withCode: "80")
    }
    
    private func emptyJSON(withCode code: String) -> Data {
        let emptyJSON: [String: Any] = [
            "code": code,
            "data": []
        ]
        return try! JSONSerialization.data(withJSONObject: emptyJSON)
    }
    
    private func makeBusStop(id: Int) -> (model: NearestBusStop, json: [String: Any]) {
        let line1 = makeBusLine(id: "\(id)1")
        let line2 = makeBusLine(id: "\(id)2")
        
        let stop = NearestBusStop(
            id: id,
            latitude: Double(id),
            longitude: Double(id),
            name: "stop \(id)",
            address: "address \(id)",
            distance: id,
            lines: [line1.model, line2.model])
        
        let stopJSON: [String: Any] = [
            "stopId": stop.id,
            "geometry": [
                "coordinates": [
                    stop.longitude,
                    stop.latitude
                ]
            ],
            "stopName": stop.name,
            "address": stop.address,
            "metersToPoint": stop.distance,
            "lines": [line1.json, line2.json]
        ]
        
        return (stop, stopJSON)
    }
    
    private func makeBusLine(id: String) -> (model: NearestBusStopLine, json: [String: Any]) {
        let line = NearestBusStopLine(
            id: id,
            origin: "origin line \(id)",
            destination: "destination line \(id)")
        
        let lineJSON: [String: Any] = [
            "line": line.id,
            "nameA": line.origin,
            "nameB": line.destination
        ]
        
        return (line, lineJSON)
    }
    
    private func trackForMemoryLeaks(_ object: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
    
    private func expect(_ sut: RemoteNearestBusStopsLoader, toCompleteWith expectedResult: RemoteNearestBusStopsLoader.LoadResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Wait for load completion")

        sut.load() { receivedResult in
            switch (receivedResult, expectedResult) {
            case let (.success(receivedBusStops), .success(expectedBusStops)):
                XCTAssertEqual(receivedBusStops, expectedBusStops, "Expected success result with bus stops \(expectedBusStops), got \(receivedBusStops) instead", file: file, line: line)

            case let (.failure(receivedError as RemoteNearestBusStopsLoader.Error), .failure(expectedError as RemoteNearestBusStopsLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, "Expected failure with error \(receivedError), got \(receivedError) instead", file: file, line: line)

            default:
                XCTFail("Expected result \(expectedResult), got \(receivedResult) instead")
                
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
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success((data, response)))
        }
    }
}
