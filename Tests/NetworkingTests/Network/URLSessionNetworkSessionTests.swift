import XCTest
@testable import Networking

final class URLSessionNetworkSessionTests: XCTestCase {
    
    // MARK: - Properties
    private let baseURL = URL(string: "https://www.test.com")!
    private var session: URLSession!
}

// MARK: - Setup
extension URLSessionNetworkSessionTests {
    
    override func setUp() {
        super.setUp()
        
        session = .shared
    }
    
    override func tearDown() {
        super.tearDown()
        
        session = nil
    }
}

// MARK: - Mocks
extension URLSessionNetworkSessionTests {
    
    private func request(httpMethod: HTTPMethod) -> AnyRequest<Void> {
        
        AnyRequest(
            httpMethod: httpMethod,
            pathComponents: ["path1", "path2"],
            headers: ["header1" : "value1", "header2" : "value2"],
            queryItems: ["query" : "value"],
            body: UUID().uuidString.data(using: .utf8),
            requiresAuthorization: false,
            transform: { _, _, _ in }
        )
    }
}

// MARK: - Tests
extension URLSessionNetworkSessionTests {
    
    func testURLSession_willCreateCorrectURLRequests_forRequests() throws {
        
        let httpMethods: [HTTPMethod : String] = [
            .get : "GET",
            .head : "HEAD",
            .post : "POST",
            .put : "PUT",
            .delete : "DELETE",
            .connect : "CONNECT",
            .options : "OPTIONS",
            .trace : "TRACE",
            .patch : "PATCH"
        ]
        
        for (httpMethod, httpMethodString) in httpMethods {
            
            let request = request(httpMethod: httpMethod)
            let urlRequest = try session.urlRequest(for: request, withBaseURL: baseURL)
            
            let expectedURL = URL(string: "\(baseURL.absoluteString)/path1/path2?query=value")
            
            XCTAssertEqual(urlRequest.url, expectedURL)
            XCTAssertEqual(urlRequest.httpMethod, httpMethodString)
            XCTAssertEqual(urlRequest.allHTTPHeaderFields, request.headers)
            XCTAssertEqual(urlRequest.httpBody, request.body)
        }
    }
}
