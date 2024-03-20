import XCTest
@testable import Networking

final class QueryEncoderTests: XCTestCase {}

// MARK: - Tests
extension QueryEncoderTests {
    
    struct EncodableValue: Encodable {
        let string = "stringValue"
        let int = 300
        let bool = true
        let double = 3.14159
    }
    
    func test_encode_willCorrectlyEncodeValue() throws {
        
        let encoder = QueryEncoder()
        let encodedValue = try encoder.encode(EncodableValue())
        
        XCTAssertEqual(encodedValue, [
            "string" : "stringValue",
            "int" : "300",
            "bool" : "true",
            "double" : "3.14159"
        ])
    }
}
