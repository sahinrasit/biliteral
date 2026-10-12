import Compression
import Foundation

public enum ZipError: Error, Equatable {
    case notAZip
    case corrupt
    case encrypted
    case unsupportedCompression(UInt16)
    case entryNotFound(String)
}

/// Read-only ZIP reader for EPUB containers: stored and deflated entries, no ZIP64.
/// Decompression uses the Compression framework (`COMPRESSION_ZLIB` is raw DEFLATE).
public struct ZipArchive: Sendable {
    public struct Entry: Sendable {
        public let path: String
        let method: UInt16
        let flags: UInt16
        let compressedSize: Int
        let uncompressedSize: Int
        let localHeaderOffset: Int
    }

    private let data: Data
    public let entries: [String: Entry]

    public init(data: Data) throws {
        let data = Data(data) // re-base slices to index 0
        self.data = data
        guard data.count >= 22 else { throw ZipError.notAZip }

        var eocd = -1
        let lowest = max(0, data.count - 22 - 0xFFFF)
        var offset = data.count - 22
        while offset >= lowest {
            if data[offset] == 0x50, data[offset + 1] == 0x4B, data[offset + 2] == 0x05, data[offset + 3] == 0x06 {
                eocd = offset
                break
            }
            offset -= 1
        }
        guard eocd >= 0 else { throw ZipError.notAZip }

        let count = Int(data.u16(eocd + 10))
        var cursor = Int(data.u32(eocd + 16))
        guard cursor < data.count else { throw ZipError.corrupt }

        var entries: [String: Entry] = [:]
        for _ in 0..<count {
            guard cursor + 46 <= data.count, data.u32(cursor) == 0x0201_4B50 else { throw ZipError.corrupt }
            let flags = data.u16(cursor + 8)
            let nameLength = Int(data.u16(cursor + 28))
            let extraLength = Int(data.u16(cursor + 30))
            let commentLength = Int(data.u16(cursor + 32))
            guard cursor + 46 + nameLength <= data.count else { throw ZipError.corrupt }
            let nameBytes = data[(cursor + 46)..<(cursor + 46 + nameLength)]
            let name = String(data: nameBytes, encoding: .utf8) ?? String(decoding: nameBytes, as: UTF8.self)
            entries[name] = Entry(path: name,
                                  method: data.u16(cursor + 10),
                                  flags: flags,
                                  compressedSize: Int(data.u32(cursor + 20)),
                                  uncompressedSize: Int(data.u32(cursor + 24)),
                                  localHeaderOffset: Int(data.u32(cursor + 42)))
            cursor += 46 + nameLength + extraLength + commentLength
        }
        self.entries = entries
    }

    public func contains(_ path: String) -> Bool { entries[path] != nil }

    public func data(for path: String) throws -> Data {
        guard let entry = entries[path] else { throw ZipError.entryNotFound(path) }
        if entry.flags & 0x1 != 0 { throw ZipError.encrypted }
        let header = entry.localHeaderOffset
        guard header + 30 <= data.count, data.u32(header) == 0x0403_4B50 else { throw ZipError.corrupt }
        let start = header + 30 + Int(data.u16(header + 26)) + Int(data.u16(header + 28))
        guard start + entry.compressedSize <= data.count else { throw ZipError.corrupt }
        let compressed = data[start..<(start + entry.compressedSize)]

        switch entry.method {
        case 0:
            return Data(compressed)
        case 8:
            guard entry.uncompressedSize > 0 else { return Data() }
            var output = Data(count: entry.uncompressedSize)
            let written = output.withUnsafeMutableBytes { (destination: UnsafeMutableRawBufferPointer) -> Int in
                compressed.withUnsafeBytes { (source: UnsafeRawBufferPointer) -> Int in
                    compression_decode_buffer(destination.bindMemory(to: UInt8.self).baseAddress!, entry.uncompressedSize,
                                              source.bindMemory(to: UInt8.self).baseAddress!, entry.compressedSize,
                                              nil, COMPRESSION_ZLIB)
                }
            }
            guard written == entry.uncompressedSize else { throw ZipError.corrupt }
            return output
        default:
            throw ZipError.unsupportedCompression(entry.method)
        }
    }

    public func string(for path: String) throws -> String {
        try data(for: path).decodedText()
    }
}

extension Data {
    func u16(_ offset: Int) -> UInt16 {
        UInt16(self[offset]) | UInt16(self[offset + 1]) << 8
    }

    func u32(_ offset: Int) -> UInt32 {
        UInt32(self[offset]) | UInt32(self[offset + 1]) << 8 | UInt32(self[offset + 2]) << 16 | UInt32(self[offset + 3]) << 24
    }

    /// UTF-8 (with or without BOM), then UTF-16 with BOM, then Windows-1252.
    func decodedText() -> String {
        if starts(with: [0xFF, 0xFE]) || starts(with: [0xFE, 0xFF]), let text = String(data: self, encoding: .utf16) {
            return text
        }
        if let text = String(data: self, encoding: .utf8) {
            return text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text
        }
        return String(data: self, encoding: .windowsCP1252) ?? String(decoding: self, as: UTF8.self)
    }
}
