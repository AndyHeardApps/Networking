import Foundation

public protocol NetworkErrorHandler<Handled> {
    
    associatedtype Handled
    
    // MARK: - Functions
    
    func handle(_ error: Error, from response: NetworkResponse<Data>) -> Handled
}
