import KeychainSwift

final class KeychainSecureStorage {
    
    // MARK: - Properties
    private let keychain: KeychainSwift
    
    // MARK: - Initialiser
    init(key: String) {
        
        self.keychain = .init(keyPrefix: "com.AndyHeardApps.Networking.\(key)")
    }
}

// MARK: - Secure storage
extension KeychainSecureStorage: SecureStorage {
    
    subscript(key: String) -> String? {
        get {
            keychain.get(key)
        }
        set {
            if let newValue = newValue {
                keychain.set(newValue, forKey: key)
            } else {
                keychain.delete(key)
            }
        }
    }
    
    func clear() {
        
        keychain.clear()
    }
}
