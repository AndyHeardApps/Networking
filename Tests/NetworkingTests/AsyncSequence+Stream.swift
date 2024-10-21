import Foundation

private final class Box<Wrapped>: @unchecked Sendable {
    
    private let lock = NSLock()
    private var _wrapped: Wrapped
    var wrapped: Wrapped {
        get {
            lock.withLock { _wrapped }
        }
        set {
            lock.withLock { _wrapped = newValue }
        }
    }
    
    init(_ wrapped: Wrapped) {
        self._wrapped = wrapped
    }
}

extension AsyncThrowingStream where Failure == Error {
    
    init<S>(_ sequence: S)
    where S: AsyncSequence,
    S.Element == Element
    {
        let iterator = Box(sequence.makeAsyncIterator())
        self.init(unfolding: {
            try await iterator.wrapped.next()
        })
    }
}

extension AsyncSequence where Element: Sendable {
    
    func eraseToThrowingStream() -> AsyncThrowingStream<Element, Error> {
        .init(self)
    }
}
