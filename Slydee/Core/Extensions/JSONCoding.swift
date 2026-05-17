import Foundation

/// Compact JSON <-> String helpers. Slide block payloads are stored as JSON
/// strings in SwiftData (see `Block`), keeping the persisted schema primitive.
nonisolated enum JSONCoding {
    static func encode<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        guard
            let data = try? encoder.encode(value),
            let string = String(data: data, encoding: .utf8)
        else { return "{}" }
        return string
    }

    static func decode<T: Decodable>(_ type: T.Type, from string: String) -> T? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
