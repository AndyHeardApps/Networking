import Foundation

extension AsyncSequence {
    
    var stream: AsyncThrowingStream<Element, Error> {
        AsyncThrowingStream(
            Element.self,
            bufferingPolicy: .unbounded
        ) { continuation in
            
            let task = Task.detached {
                do {
                    for try await element in self {
                        
                        if Task.isCancelled { break }
                        
                        let yieldResult = continuation.yield(element)
                        
                        let shouldBreak: Bool
                        switch yieldResult {
                        case .enqueued, .dropped:
                            shouldBreak = false
                        case .terminated:
                            shouldBreak = true
                        @unknown default:
                            shouldBreak = true
                        }
                        
                        if shouldBreak {
                            break
                        }
                    }
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: error)
                    
                }
            }
            
            continuation.onTermination = { termination in
                switch termination {
                case .finished:
                    break
                case .cancelled:
                    task.cancel()
                @unknown default:
                    task.cancel()
                }
            }
        }
    }
}
