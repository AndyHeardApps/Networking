import Foundation
import Testing
@testable import Networking

@Suite(
    "Data coders",
    .tags(.http, .webSocket)
)
struct DataCodersTests {

    // MARK: - Properties
    private var coders: DataCoders
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    // MARK: - Initializer
    init() {

        self.coders = .init()
        self.jsonEncoder = .init()
        self.jsonDecoder = .init()

        coders.set(jsonEncoder, for: .json)
        coders.set(jsonDecoder, for: .json)
    }
}

// MARK: - Mock data coders
extension DataCodersTests {
    private struct MockDataEncoder: DataEncoder {
        
        func encode(_ value: some Encodable) throws -> Data {
            
            .init()
        }
    }
    
    private struct MockDataDecoder: DataDecoder {
        
        func decode<T: Decodable>(_ type: T.Type, from: Data) throws -> T {
            
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: ""))
        }
    }
}

// MARK: - Tests
extension DataCodersTests {
    
    @Test("requireDecoder returns correct value")
    mutating func requireDecoderReturnsCorrectValue() throws {

        coders.set(MockDataDecoder(), for: .octetStream)
        
        #expect(try coders.requireDecoder(for: .json) as? JSONDecoder === jsonDecoder)
        #expect(try coders.requireDecoder(for: .octetStream) is MockDataDecoder)
    }
    
    @Test("requireEncoder returns correct value")
    mutating func requireEncoderReturnsCorrectValue() throws {

        coders.set(MockDataEncoder(), for: .octetStream)
        
        #expect(try coders.requireEncoder(for: .json) as? JSONEncoder === jsonEncoder)
        #expect(try coders.requireEncoder(for: .octetStream) is MockDataEncoder)
    }
    
    @Test("requireDecoder throws error for unset type")
    func requireDecoderThrowsErrorForUnsetType() {

        #expect(throws: DataCoders.Error.decoderNotSet(contentType: .octetStream)) {
            try coders.requireDecoder(for: .octetStream)
        }
    }
    
    @Test("requireEncoder throws error for unset type")
    func requireEncoderThrowsErrorForUnsetType() {

        #expect(throws: DataCoders.Error.encoderNotSet(contentType: .octetStream)) {
            try coders.requireEncoder(for: .octetStream)
        }
    }
}
