import Foundation
import Testing
@testable import Networking

@Suite(
    "HTTPController extensions",
    .tags(.http)
)
struct HTTPControllerExtensionTests {

    // MARK: - Properties
    private let httpController: MockHTTPController

    // MARK: - Initializer
    init() {
        self.httpController = MockHTTPController()
    }
}

// MARK: - Tests
extension HTTPControllerExtensionTests {
 
    @Test("fetchContent will return content from fetchResponse")
    func fetchContentWillReturnContentFromFetchResponse() async throws {

        httpController.responseStatusCode = .ok
        httpController.responseData = UUID().uuidString.data(using: .utf8)!
        
        let request = MockHTTPRequest { body, _, _ in
            body
        } decode: { data, _, _ in
            Data(data.reversed())
        }
        
        let response = try await httpController.fetchContent(request)
        
        #expect(response == Data(httpController.responseData.reversed()))
    }
}
