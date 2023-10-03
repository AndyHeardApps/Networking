import Foundation

public protocol NetworkWebSocketRequest<Input, Output> {
    
    associatedtype Input
    
    associatedtype Output
    
    // MARK: - Properties
    
    /// The path components of the request `URL`. These will be combined in order to build the `URL`, so there is not need to include any `/`.
    var pathComponents: [String] { get }
    
    /// The headers of the request.
    var headers: [String : String]? { get }
    
    /// The query items of the request `URL`.
    var queryItems: [String : String]? { get }
        
    /// Whether or not the request will require authorization credentials attaching. If so, then ``AuthorizingNetworkController`` and ``ReauthorizingNetworkController`` types will authorize the request before submission.
    var requiresAuthorization: Bool { get }
    
    // MARK: - Functions
    func transform(input: Input) throws -> Data
    
    func transform(data: Data) throws -> Output
}
