import Foundation
import Testing
@testable import Networking

@Suite(
    "URLSession web socket session",
    .tags(.webSocket)
)
struct URLSessionWebSocketSessionTests {

    // MARK: - Properties
    private let baseURL = URL(string: "https://test.domain.com")!
    private let urlSession: URLSession

    // MARK: - Initializer
    init() {
        self.urlSession = .shared
    }
}

// MARK: - Tests
extension URLSessionWebSocketSessionTests {
    
    @Test("openConnection creates web socket task")
    func openConnectionCreatesWebSocketTask() async throws {

        let request = AnyWebSocketRequest<Data, Data>(
            pathComponents: ["path1", "path2"],
            headers: ["header1" : "value1", "header2" : "value2"],
            queryItems: ["query1" : "value3"],
            encode: { data, _ in data },
            decode: { data, _ in data }
        )
        let interface = try urlSession.createInterface(to: request, with: baseURL)
        
        let webSocketTask = try #require(interface as? URLSessionWebSocketTask)
        let originalRequest = try #require(webSocketTask.originalRequest)

        #expect(originalRequest.url?.absoluteString == "https://test.domain.com/path1/path2?query1=value3")
        #expect(originalRequest.allHTTPHeaderFields?["header1"] == "value1")
        #expect(originalRequest.allHTTPHeaderFields?["header1"] == "value1")
        #expect(originalRequest.httpMethod == "GET")
        #expect(originalRequest.httpBody == nil)
    }
}
