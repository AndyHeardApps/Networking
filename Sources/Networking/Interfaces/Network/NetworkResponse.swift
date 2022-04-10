
/// A container for basic network responses.
public struct NetworkResponse<Content> {
    
    // MARK: - Properties
    
    /// The contents of the response. This can be raw `Data` or a more specific Swift type.
    let content: Content
    
    /// The status code returned by the request.
    let statusCode: HTTPStatusCode
    
    /// The headers returned by the request.
    let headers: [AnyHashable : String]
}
