
public protocol WebSocketAuthorizationProvider {
    
    func authorize<Request: WebSocketRequest>(request: Request) throws -> any WebSocketRequest<Request.Input, Request.Output>
    
     
}
