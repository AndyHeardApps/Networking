import Foundation

public protocol NetworkRequest<ResponseType> {

    associatedtype ResponseType

    // MARK: - Properties
    
    var httpMethod: HTTPMethod { get }
    
    var pathComponents: [String] { get }
    
    var headers: [String : String]? { get }
    
    var queryItems: [String : String]? { get }
    
    var body: Data? { get }
    
    var requiresAuthorization: Bool { get }
    
    // MARK: - Functions
    
    func transform(data: Data, statusCode: HTTPStatusCode, using decoder: DataDecoder) throws -> ResponseType
}
