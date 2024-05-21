import Foundation

extension AsyncSequence where Element: Sendable {

    var stream: AsyncThrowingStream<Element, Error> {
        
        let lock = NSLock()
        var iterator: Self.AsyncIterator?
        return AsyncThrowingStream {
            lock.withLock {
                if iterator == nil {
                    iterator = self.makeAsyncIterator()
                }
            }
            return try await iterator?.next()
        }
    }
}
