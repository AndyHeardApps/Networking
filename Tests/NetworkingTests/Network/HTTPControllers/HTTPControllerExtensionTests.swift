import XCTest
@testable import Networking

final class HTTPControllerExtensionTests: XCTestCase {

    // MARK: - Properties
    private var httpController: MockHTTPController!
}

// MARK: - Setup
extension HTTPControllerExtensionTests {

    override func setUp() {
        super.setUp()

        self.httpController = MockHTTPController()
    }

    override func tearDown() {
        super.tearDown()

        self.httpController = nil
    }
}

// MARK: - Tests
extension HTTPControllerExtensionTests {
 
    func testFetchContent_willReturnContentFromFetchResponse() async throws {
        
        httpController.responseStatusCode = .ok
        httpController.responseData = UUID().uuidString.data(using: .utf8)!
        
        let request = MockHTTPRequest { data, _, _ in
            Data(data.reversed())
        }
        
        let response = try await httpController.fetchContent(request)
        
        XCTAssertEqual(response, Data(httpController.responseData.reversed()))
    }
}
