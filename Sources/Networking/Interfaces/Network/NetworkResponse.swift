
public struct NetworkResponse<Content> {
    
    // MARK: - Properties
    
    public let content: Content
    
    public let statusCode: HTTPStatusCode
    
    public let headers: [AnyHashable : String]
    
    // MARK: - Initialiser
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
