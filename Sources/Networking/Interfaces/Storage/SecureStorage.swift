
protocol SecureStorage: AnyObject & Sendable {
    
    // MARK: - Subscripts
    subscript(_ key: String) -> String? { get set }
}
