@testable import Networking

final class MockSecureStorage {
    
    // MARK: - Properties
    private var storage: [String : String] = [:]
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
