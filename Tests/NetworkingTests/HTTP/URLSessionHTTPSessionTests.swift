import Foundation
import Testing
@testable import Networking

@Suite(
    "URLSession HTTPSession",
    .tags(.http),
    .serialized
)
struct URLSessionHTTPSessionTests {

    // MARK: - Properties
    private let baseURL = URL(string: "https://test.domain.com")!
    private let urlSession: URLSession

    // MARK: - Initializer
    init() {

        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        self.urlSession = URLSession(configuration: configuration)
    }
}

// MARK: - Mocks
extension URLSessionHTTPSessionTests {
    
    final class MockURLProtocol: URLProtocol {
        
        // Properties
        nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

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
    
    @Test(
        "submitRequest creates and submits correct URLRequest",
        arguments: [
            HTTPMethod.get : "GET",
            HTTPMethod.head : "HEAD",
            HTTPMethod.post : "POST",
            HTTPMethod.put : "PUT",
            HTTPMethod.delete : "DELETE",
            HTTPMethod.connect : "CONNECT",
            HTTPMethod.options : "OPTIONS",
            HTTPMethod.trace : "TRACE",
            HTTPMethod.patch : "PATCH"
        ]
    )
    func submitRequestCreatesAndSubmitsCorrectURLRequest(httpMethod: HTTPMethod, httpMethodString: String) async throws {

        let request = MockHTTPRequest(
            httpMethod: httpMethod,
            body: Data(UUID().uuidString.utf8)
        )

        MockURLProtocol.requestHandler = { urlRequest in
            
            let expectedURLString = baseURL.absoluteString
            + "/"
            + request.pathComponents.joined(separator: "/")
            + "?"
            + request.queryItems!.map { "\($0)=\($1)" }.joined(separator: "/")
            var expectedHeaders = request.headers
            expectedHeaders?["Content-Length"] = "36"
            
            #expect(urlRequest.url?.absoluteString == expectedURLString)
            #expect(urlRequest.httpMethod == httpMethodString)
            #expect(urlRequest.httpBody == request.body)
            let expectedTimeout = URLRequest(url: baseURL).timeoutInterval
            #expect(urlRequest.timeoutInterval == expectedTimeout)
            #expect(urlRequest.allHTTPHeaderFields == expectedHeaders)

            return (HTTPURLResponse(), nil)
        }
        
        _ = try await urlSession.submit(request: request, to: baseURL)
    }

    @Test("submitRequest sets timeout if present")
    func submitRequestSetsTimeoutIfPresent() async throws {
      
        MockURLProtocol.requestHandler = { urlRequest in
            
            #expect(urlRequest.timeoutInterval == 180)
            
            return (HTTPURLResponse(), nil)
        }

        let request = MockHTTPRequest(
            httpMethod: .post,
            timeoutInterval: 180,
            body: Data(UUID().uuidString.utf8)
        )
        _ = try await urlSession.submit(request: request, to: baseURL)
    }

    @Test("submitRequest uses default timeout if not provided")
    func submitRequestUsesDefaultTimeoutIfNotProvided() async throws {
    
        var receivedURLRequest: URLRequest?
        MockURLProtocol.requestHandler = { urlRequest in
            receivedURLRequest = urlRequest
            return (HTTPURLResponse(), nil)
        }

        let request = MockHTTPRequest(
            httpMethod: .post,
            body: Data(UUID().uuidString.utf8)
        )
        _ = try await urlSession.submit(request: request, to: baseURL)

        #expect(receivedURLRequest != nil)
        let expectedTimeout = URLRequest(url: baseURL).timeoutInterval
        #expect(receivedURLRequest?.timeoutInterval == expectedTimeout)
    }
}
