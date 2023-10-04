
/// Contains the response for a ``NetworkRequest``, wrapping some generic ``content``, a ``statusCode``, and the ``headers``.
///
/// This type is often used to wrap raw `Data` before a ``NetworkRequest`` has transformed it into some more specific type.
public struct NetworkResponse<Content> {
    
    // MARK: - Properties
    
    /// The generic contents of the response.
    public let content: Content
    
    /// The status code returned from the network.
    public let statusCode: HTTPStatusCode
    
    /// The headers of the response.
    public let headers: [AnyHashable : String]
    
    // MARK: - Initialiser
    
    /// Creates a new ``NetworkResponse`` instance.
    public init(
        content: Content,
        statusCode: HTTPStatusCode,
        headers: [AnyHashable : String]
    ) {
        
        self.content = content
        self.statusCode = statusCode
        self.headers = headers
    }
}
