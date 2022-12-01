import XCTest
@testable import Networking

final class NetworkControllerExtensionTests: XCTestCase {

    // MARK: - Properties
    private var networkController: MockNetworkController!
}

// MARK: - Setup
extension NetworkControllerExtensionTests {

    override func setUp() {
        super.setUp()

        self.networkController = MockNetworkController()
    }

    override func tearDown() {
        super.tearDown()

        self.networkController = nil
    }
}

// MARK: - Tests
extension NetworkControllerExtensionTests {
 
    func testFetchContent_willReturnContentFromFetchResponse() async throws {
        
        networkController.responseStatusCode = .ok
        networkController.responseData = UUID().uuidString.data(using: .utf8)!
        
        let request = MockNetworkRequest { data, _, _ in
            Data(data.reversed())
        }
        
        let response = try await networkController.fetchContent(request)
        
        XCTAssertEqual(response, Data(networkController.responseData.reversed()))
    }
}
