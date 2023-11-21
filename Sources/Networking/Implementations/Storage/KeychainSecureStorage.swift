#if canImport(Security)
import Foundation
import Security

final class KeychainSecureStorage {
    
    // MARK: - Properties
    private let keyPrefix = "com.AndyHeardApps.Networking."
    
    // MARK: - Initialiser
    init() {}
}

// MARK: - Secure storage
extension KeychainSecureStorage: SecureStorage {
    
    subscript(key: String) -> String? {
        get {
            let prefixedKey = keyPrefix + key
            let getQuery: [String : Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: prefixedKey,
                kSecReturnData as String: true
            ]
            var item: AnyObject?
            let status = withUnsafeMutablePointer(to: &item) {
                SecItemCopyMatching(getQuery as CFDictionary, UnsafeMutablePointer($0))
            }
            
            if
                status == noErr,
                let data = item as? Data,
                let string = String(data: data, encoding: .utf8)
            {
                return string
            }
            return nil
        }
        set {
            let prefixedKey = keyPrefix + key
            let deleteQuery: [String : Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: prefixedKey,
                kSecReturnData as String: false
            ]
            _ = SecItemDelete(deleteQuery as CFDictionary)

            if let newValue {
                let addQuery: [String: Any] = [
                    kSecClass as String : kSecClassGenericPassword,
                    kSecAttrAccount as String : prefixedKey,
                    kSecValueData as String : Data(newValue.utf8)
                ]
                _ = SecItemAdd(addQuery as CFDictionary, nil)
            }
        }
    }
    
    func clear() {
        
//        keychain.clear()
    }
}
#endif
