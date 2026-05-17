import Foundation

/// Minimal ZIP writer (store method, no compression) — iOS has no public ZIP
/// archive API. Sufficient for OOXML (.pptx) containers, which accept stored
/// entries. Not general-purpose; entries are written in add order.
nonisolated struct ZIPArchive {
    private struct Entry {
        let name: String
        let data: Data
        let crc: UInt32
        var offset: UInt32 = 0
    }

    private var entries: [Entry] = []

    mutating func addFile(_ name: String, _ data: Data) {
        entries.append(Entry(name: name, data: data, crc: Self.crc32(data)))
    }

    mutating func addFile(_ name: String, string: String) {
        addFile(name, Data(string.utf8))
    }

    /// Serializes the archive.
    func data() -> Data {
        var out = Data()
        var central = Data()
        var local = entries

        for index in local.indices {
            local[index].offset = UInt32(out.count)
            let entry = local[index]
            let nameBytes = Array(entry.name.utf8)

            // Local file header
            out.append(le32: 0x0403_4B50)
            out.append(le16: 20) // version needed
            out.append(le16: 0) // flags
            out.append(le16: 0) // method: store
            out.append(le16: 0) // mod time
            out.append(le16: 0x21) // mod date (1980-01-01-ish)
            out.append(le32: entry.crc)
            out.append(le32: UInt32(entry.data.count)) // compressed
            out.append(le32: UInt32(entry.data.count)) // uncompressed
            out.append(le16: UInt16(nameBytes.count))
            out.append(le16: 0) // extra len
            out.append(contentsOf: nameBytes)
            out.append(entry.data)

            // Central directory record
            central.append(le32: 0x0201_4B50)
            central.append(le16: 20) // version made by
            central.append(le16: 20) // version needed
            central.append(le16: 0)
            central.append(le16: 0) // store
            central.append(le16: 0)
            central.append(le16: 0x21)
            central.append(le32: entry.crc)
            central.append(le32: UInt32(entry.data.count))
            central.append(le32: UInt32(entry.data.count))
            central.append(le16: UInt16(nameBytes.count))
            central.append(le16: 0) // extra
            central.append(le16: 0) // comment
            central.append(le16: 0) // disk number
            central.append(le16: 0) // internal attrs
            central.append(le32: 0) // external attrs
            central.append(le32: entry.offset)
            central.append(contentsOf: nameBytes)
        }

        let centralOffset = UInt32(out.count)
        out.append(central)

        // End of central directory
        out.append(le32: 0x0605_4B50)
        out.append(le16: 0)
        out.append(le16: 0)
        out.append(le16: UInt16(local.count))
        out.append(le16: UInt16(local.count))
        out.append(le32: UInt32(central.count))
        out.append(le32: centralOffset)
        out.append(le16: 0)
        return out
    }

    // MARK: CRC32

    private static let crcTable: [UInt32] = {
        (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1) != 0 ? (0xEDB8_8320 ^ (c >> 1)) : (c >> 1)
            }
            return c
        }
    }()

    static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = crcTable[index] ^ (crc >> 8)
        }
        return crc ^ 0xFFFF_FFFF
    }
}

private nonisolated extension Data {
    mutating func append(le16 value: UInt16) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
    }

    mutating func append(le32 value: UInt32) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8((value >> 16) & 0xFF))
        append(UInt8((value >> 24) & 0xFF))
    }
}
