import XCTest
@testable import Networking

final class DefaultAuthorizationErrorHandlerTests: XCTestCase {
    
    // MARK: - Properties
    private var authorizationErrorHandler: DefaultAuthorizationErrorHandler!
}

// MARK: - Setup
extension DefaultAuthorizationErrorHandlerTests {
    
    override func setUp() {
        super.setUp()
        
        self.authorizationErrorHandler = .init()
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.authorizationErrorHandler = nil
    }
}

// MARK: - Tests
extension DefaultAuthorizationErrorHandlerTests {
    
    func testHandleError_willReturnErrorForNonUnauthorizedStatusCode() {
        
        let networkResponse = NetworkResponse(
            content: Data(),
            statusCode: .badRequest,
            headers: [:]
        )
        
        let errorHandlerResponse = authorizationErrorHandler.handle(
            HTTPStatusCode.badRequest,
            from: networkResponse
        )
        
        switch errorHandlerResponse {
        case .error(HTTPStatusCode.badRequest):
            break
            
        default:
            XCTFail()
            
        }
    }
    
    func testHandleError_willNotThrowErrorForUnauthorizedStatusCode() {
        
        let networkResponse = NetworkResponse(
            content: Data(),
            statusCode: .unauthorized,
            headers: [:]
        )
        
        let errorHandlerResponse = authorizationErrorHandler.handle(
            HTTPStatusCode.unauthorized,
            from: networkResponse
        )
        
        switch errorHandlerResponse {
        case .attemptReauthorization:
            break
            
        default:
            XCTFail()
            
        }
    }
}
