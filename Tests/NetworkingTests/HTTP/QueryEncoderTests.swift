import Foundation
import Testing
@testable import Networking

@Suite(
    "Query encoder",
    .tags(.http)
)
struct QueryEncoderTests {}

// MARK: - Tests
extension QueryEncoderTests {
    
    struct EncodableValue: Encodable {
        let string = "stringValue"
        let int = 300
        let bool = true
        let double = 3.14159
    }
    
    @Test("Correctly encodes values")
    func correctlyEncodesValues() throws {

        let encoder = QueryEncoder()
        let encodedValue = try encoder.encode(EncodableValue())
        
        #expect(encodedValue == [
            "string" : "stringValue",
            "int" : "300",
            "bool" : "true",
            "double" : "3.14159"
        ])
    }
}
