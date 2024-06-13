#if canImport(Security)
import Foundation
import Testing
@testable import Networking

@Suite(
    "Keychain secure storage",
    .tags(.http, .webSocket)
)
final class KeychainSecureStorageTests {

    // MARK: - Properties
    private let storage: KeychainSecureStorage

    // MARK: - Initializer
    init() {

        self.storage = KeychainSecureStorage()
    }

    deinit {
        storage.clear()
    }
}

// MARK: - Tests
extension KeychainSecureStorageTests {

    @Test("Read, write and delete")
    func readWriteAndDelete() {

        let key = "testKey"
        let value = "testValue"

        #expect(storage[key] == nil)
        storage[key] = value

        #expect(storage[key] == value)
        storage[key] = nil

        #expect(storage[key] == nil)
    }
}
#endif
