/// Defines a list of close codes that a web socket interface can use.
public enum WebSocketInterfaceCloseCode: Sendable {

    // MARK: - Cases
    case invalid
    case normalClosure
    case goingAway
    case protocolError
    case unsupportedData
    case noStatusReceived
    case abnormalClosure
    case invalidFramePayloadData
    case policyViolation
    case messageTooBig
    case mandatoryExtensionMissing
    case internalServerError
    case tlsHandshakeFailure
}
