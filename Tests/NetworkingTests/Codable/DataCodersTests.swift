import XCTest
@testable import Networking

final class DataCodersTests: XCTestCase {

    // MARK: - Properties
    private var coders: DataCoders!
    private var jsonEncoder: JSONEncoder!
    private var jsonDecoder: JSONDecoder!
}

// MARK: - Setup
extension DataCodersTests {
    
    override func setUp() {
        super.setUp()
        
        self.coders = .init()
        self.jsonEncoder = .init()
        self.jsonDecoder = .init()
        
        coders.set(jsonEncoder, for: .json)
        coders.set(jsonDecoder, for: .json)
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.coders = nil
        self.jsonEncoder = nil
        self.jsonDecoder = nil
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
    
    func test_requireDecoder_willThrowReturnCorrectDecoder() {
        
        coders.set(MockDataDecoder(), for: .octetStream)
        
        XCTAssertIdentical(try coders.requireDecoder(for: .json) as? JSONDecoder, jsonDecoder)
        XCTAssertTrue(try coders.requireDecoder(for: .octetStream) is MockDataDecoder)
    }
    
    func test_requireEncoder_willThrowReturnCorrectEncoder() {
        
        coders.set(MockDataEncoder(), for: .octetStream)
        
        XCTAssertIdentical(try coders.requireEncoder(for: .json) as? JSONEncoder, jsonEncoder)
        XCTAssertTrue(try coders.requireEncoder(for: .octetStream) is MockDataEncoder)
    }
    
    func test_requireDecoder_willThrowErrorWhenDecoderForTypeNotSet() {
        
        XCTAssertThrowsError(try coders.requireDecoder(for: .octetStream)) { error in
            guard case .decoderNotSet(contentType: .octetStream) = error as? DataCoders.Error else {
                XCTFail()
                return
            }
            XCTAssertEqual(error.localizedDescription, "No decoder set for 'Content-Type' application/octet-stream")
        }
    }
    
    func test_requireEncoder_willThrowErrorWhenEncoderForTypeNotSet() {

        XCTAssertThrowsError(try coders.requireEncoder(for: .octetStream)) { error in
            guard case .encoderNotSet(contentType: .octetStream) = error as? DataCoders.Error else {
                XCTFail()
                return
            }
            XCTAssertEqual(error.localizedDescription, "No encoder set for 'Content-Type' application/octet-stream")
        }
    }
}
