import XCTest
@testable import Networking

final class URLSessionHTTPSessionTests: XCTestCase {
    
    // MARK: - Properties
    private var baseURL: URL!
    private var urlSession: URLSession!
}

// MARK: - Setup
extension URLSessionHTTPSessionTests {
    
    override func setUp() {
        super.setUp()
        
        self.baseURL = URL(string: "https://test.domain.com")
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        self.urlSession = URLSession(configuration: configuration)
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.baseURL = nil
        self.urlSession = nil
    }
}

// MARK: - Mocks
extension URLSessionHTTPSessionTests {
    
    final class MockURLProtocol: URLProtocol {
        
        // Properties
        @MainActor
        static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?
        
        // URL protocol
        override class func canInit(with request: URLRequest) -> Bool {
            true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            
            var request = request
            if let bodyStream = request.httpBodyStream {
                
                bodyStream.open()
                
                let bufferSize: Int = 16
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                var data = Data()

                while bodyStream.hasBytesAvailable {

                    let readData = bodyStream.read(buffer, maxLength: bufferSize)
                    data.append(buffer, count: readData)
                }

                buffer.deallocate()
                bodyStream.close()
                
                request.httpBody = data
            }
            
            return request
        }
        
        @MainActor
        override func startLoading() {
            
            guard let handler = MockURLProtocol.requestHandler else {
                fatalError("Handler is unavailable.")
            }
            
            do {

                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                
                if let data {
                    client?.urlProtocol(self, didLoad: data)
                }
                
                client?.urlProtocolDidFinishLoading(self)
                
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
                
            }
        }
        
        override func stopLoading() {}
    }
}

// MARK: - Tests
extension URLSessionHTTPSessionTests {
    
    @MainActor
    func test_submitRequest_willCorrectlyCreateURLRequest_andSubmitIt() async throws {
        
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
            
            var receivedURLRequest: URLRequest?
            MockURLProtocol.requestHandler = { urlRequest in
                receivedURLRequest = urlRequest
                return (HTTPURLResponse(), nil)
            }
            
            let request = MockHTTPRequest(
                httpMethod: httpMethod,
                body: Data(UUID().uuidString.utf8)
            )
            _ = try await urlSession.submit(request: request, to: baseURL)
                    
            let expectedURLString = baseURL.absoluteString
                + "/"
                + request.pathComponents.joined(separator: "/")
                + "?"
                + request.queryItems!.map { "\($0)=\($1)" }.joined(separator: "/")
            var expectedHeaders = request.headers
            expectedHeaders?["Content-Length"] = "36"
            
            XCTAssertNotNil(receivedURLRequest)
            XCTAssertEqual(receivedURLRequest?.url?.absoluteString, expectedURLString)
            XCTAssertEqual(receivedURLRequest?.httpMethod, httpMethodString)
            XCTAssertEqual(receivedURLRequest?.httpBody, request.body)
            XCTAssertEqual(receivedURLRequest?.allHTTPHeaderFields, expectedHeaders)
        }
    }
}
