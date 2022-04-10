
protocol SecureStorage: AnyObject {
    
    // MARK: - Subscripts
    subscript(_ key: String) -> String? { get set }
}
