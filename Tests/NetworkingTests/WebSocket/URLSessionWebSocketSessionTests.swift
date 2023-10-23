import XCTest
@testable import Networking

final class URLSessionWebSocketSessionTests: XCTestCase {
    
    // MARK: - Properties
    private var baseURL: URL!
    private var urlSession: URLSession!
}

// MARK: - Setup
extension URLSessionWebSocketSessionTests {
    
    override func setUp() {
        super.setUp()
        
        self.baseURL = URL(string: "https://test.domain.com")
        self.urlSession = .shared
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.baseURL = nil
        self.urlSession = nil
    }
}

// MARK: - Tests
extension URLSessionWebSocketSessionTests {
    
    func test_openConnection_willCorrectlyCreateWebSocketTask() async throws {
        
        let request = AnyWebSocketRequest<Data, Data>(
            pathComponents: ["path1", "path2"],
            headers: ["header1" : "value1", "header2" : "value2"],
            queryItems: ["query1" : "value3"],
            encode: { data, _ in data },
            decode: { data, _ in data }
        )
        let interface = try urlSession.openConnection(to: request, with: baseURL)
        
        guard let webSocketTask = interface as? URLSessionWebSocketTask else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(webSocketTask.originalRequest?.url?.absoluteString, "https://test.domain.com/path1/path2?query1=value3")
        XCTAssertEqual(webSocketTask.originalRequest?.allHTTPHeaderFields?["header1"], "value1")
        XCTAssertEqual(webSocketTask.originalRequest?.allHTTPHeaderFields?["header1"], "value1")
        XCTAssertEqual(webSocketTask.originalRequest?.httpMethod, "GET")
        XCTAssertNil(webSocketTask.originalRequest?.httpBody)
    }
}
