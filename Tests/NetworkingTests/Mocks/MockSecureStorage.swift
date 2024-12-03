@testable import Networking

final class MockSecureStorage: @unchecked Sendable {
    
    // MARK: - Properties
    private(set) var storage: [String : String] = [:]
}

// MARK: - Secure storage
extension MockSecureStorage: SecureStorage {
    
    subscript(key: String) -> String? {
        get {
            storage[key]
        }
        set(newValue) {
            storage[key] = newValue
        }
    }
}
