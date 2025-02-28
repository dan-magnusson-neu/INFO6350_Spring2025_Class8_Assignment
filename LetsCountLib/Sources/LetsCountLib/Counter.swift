public protocol Counter: Sendable, Codable {
    var currentValue: Int? { get }
}
public struct CounterRequest: Counter {
    public var currentValue: Int?
    
    private enum CodingKeys: String, CodingKey {
        case currentValue = "current_value"
    }
}
public struct CounterResponse: Counter, CustomStringConvertible {
    public let currentValue: Int?
    public let namespace: String?
    public let key: String?
    public let exists: Bool? = nil
    public var description: String {
        "\(namespace?.description ?? "nil")/\(key?.description ?? "nil"): \(currentValue?.description ?? "nil")"
    }
    private enum CodingKeys: String, CodingKey {
        case currentValue = "current_value"
        case namespace, key, exists
    }
}
