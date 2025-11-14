import Foundation
import Compression

public enum CodecError: Error {
    case decompressionFailed
    case compressionFailed
    case invalidUTF8
}

public struct Codec {

    // MARK: - Custom Base64 Table
    private static let table: [UInt8] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=").map { UInt8($0.asciiValue!) }

    private static let decodeTable: [UInt8: UInt8] = {
        var map = [UInt8: UInt8]()
        for (i, c) in table.enumerated() {
            map[c] = UInt8(i)
        }
        return map
    }()

    // MARK: - Base64 Decode
    public static func decode(_ data: Data) -> Data {
        var bytes = [UInt8](data)
        bytes = bytes.compactMap { decodeTable[$0] }

        // truncate at first pad (=)
        if let padIndex = bytes.firstIndex(of: 64) {
            bytes.removeSubrange(padIndex..<bytes.count)
        }

        var out = [UInt8]()
        let fullBlocks = bytes.count / 4 * 4

        // decode full 4-byte blocks
        for i in stride(from: 0, to: fullBlocks, by: 4) {
            let a = bytes[i]
            let b = bytes[i+1]
            let c = bytes[i+2]
            let d = bytes[i+3]

            out.append((a << 2) | (b >> 4))
            out.append(((b & 0x0F) << 4) | (c >> 2))
            out.append(((c & 0x03) << 6) | d)
        }

        // handle leftover 1-2 bytes
        let leftover = bytes.count % 4
        let index = fullBlocks
        if leftover == 2 {
            let a = bytes[index]
            let b = bytes[index+1]
            out.append((a << 2) | (b >> 4))
        } else if leftover == 3 {
            let a = bytes[index]
            let b = bytes[index+1]
            let c = bytes[index+2]
            out.append((a << 2) | (b >> 4))
            out.append(((b & 0x0F) << 4) | (c >> 2))
        }

        return Data(out)
    }

    // MARK: - Base64 Encode
    public static func encode(_ data: Data) -> Data {
        let bytes = [UInt8](data)
        var out = [UInt8]()

        for i in stride(from: 0, to: bytes.count, by: 3) {
            let chunk = bytes[i..<min(i+3, bytes.count)]
            var b: [UInt8] = Array(repeating: 0, count: 4)

            switch chunk.count {
            case 3:
                b[0] = chunk[0] >> 2
                b[1] = ((chunk[0] & 0x03) << 4) | (chunk[1] >> 4)
                b[2] = ((chunk[1] & 0x0F) << 2) | (chunk[2] >> 6)
                b[3] = chunk[2] & 0x3F
            case 2:
                b[0] = chunk[0] >> 2
                b[1] = ((chunk[0] & 0x03) << 4) | (chunk[1] >> 4)
                b[2] = ((chunk[1] & 0x0F) << 2)
                b[3] = 64
            case 1:
                b[0] = chunk[0] >> 2
                b[1] = ((chunk[0] & 0x03) << 4)
                b[2] = 64
                b[3] = 64
            default: break
            }
            out.append(contentsOf: b.map { table[Int($0)] })
        }
        return Data(out)
    }

    // MARK: - Zlib Inflate
    public static func inflate(_ data: Data) throws -> Data {
        return try data.withUnsafeBytes { src in
            guard let ptr = src.baseAddress?.assumingMemoryBound(to: UInt8.self) else { throw CodecError.decompressionFailed }
            let dstCap = 10_000_000
            let dst = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCap)
            defer { dst.deallocate() }
            let size = compression_decode_buffer(dst, dstCap, ptr, data.count, nil, COMPRESSION_ZLIB)
            guard size > 0 else { throw CodecError.decompressionFailed }
            return Data(bytes: dst, count: size)
        }
    }

    // MARK: - Zlib Deflate
    public static func deflate(_ data: Data) throws -> Data {
        return try data.withUnsafeBytes { src in
            guard let ptr = src.baseAddress?.assumingMemoryBound(to: UInt8.self) else { throw CodecError.compressionFailed }
            let dstCap = 10_000_000
            let dst = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCap)
            defer { dst.deallocate() }
            let size = compression_encode_buffer(dst, dstCap, ptr, data.count, nil, COMPRESSION_ZLIB)
            guard size > 0 else { throw CodecError.compressionFailed }
            return Data(bytes: dst, count: size)
        }
    }

    // MARK: - High-Level Decode Data
    public static func decodeData(_ data: Data) throws -> String {
        let decoded = decode(data)
        let inflated = try inflate(decoded)
        guard let text = String(data: inflated, encoding: .utf8) else { throw CodecError.invalidUTF8 }
        return text
    }

    // MARK: - High-Level Encode Data
    public static func encodeData(_ json: String) throws -> Data {
        guard let jsonData = json.data(using: .utf8) else { throw CodecError.invalidUTF8 }
        let deflated = try deflate(jsonData)
        return encode(deflated)
    }
}
