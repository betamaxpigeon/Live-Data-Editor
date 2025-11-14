import Foundation
import CommonCrypto
import Compression

// MARK: - AES-CBC Encryption / Decryption
public struct Crypto {
    public static func aesCBCDecrypt(data: Data, key: Data, iv: Data) -> Data? {
        var outLength = 0
        var outBytes = [UInt8](repeating: 0, count: data.count + kCCBlockSizeAES128)
        
        let status = CCCrypt(CCOperation(kCCDecrypt),
                             CCAlgorithm(kCCAlgorithmAES),
                             CCOptions(kCCOptionPKCS7Padding),
                             [UInt8](key),
                             kCCKeySizeAES128,
                             [UInt8](iv),
                             [UInt8](data),
                             data.count,
                             &outBytes,
                             outBytes.count,
                             &outLength)
        if status == kCCSuccess {
            return Data(bytes: outBytes, count: outLength)
        }
        return nil
    }
    
    public static func aesCBCEncrypt(data: Data, key: Data, iv: Data) -> Data? {
        var outLength = 0
        var outBytes = [UInt8](repeating: 0, count: data.count + kCCBlockSizeAES128)
        
        let status = CCCrypt(CCOperation(kCCEncrypt),
                             CCAlgorithm(kCCAlgorithmAES),
                             CCOptions(kCCOptionPKCS7Padding),
                             [UInt8](key),
                             kCCKeySizeAES128,
                             [UInt8](iv),
                             [UInt8](data),
                             data.count,
                             &outBytes,
                             outBytes.count,
                             &outLength)
        if status == kCCSuccess {
            return Data(bytes: outBytes, count: outLength)
        }
        return nil
    }
}

// MARK: - zlib Inflate / Deflate
public extension Data {
    func inflate() -> Data? {
        return self.withUnsafeBytes { (src: UnsafeRawBufferPointer) -> Data? in
            guard let srcPtr = src.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return nil }
            let srcSize = self.count
            
            let dstCapacity = 10_000_000
            let dstBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCapacity)
            defer { dstBuffer.deallocate() }
            
            let decodedSize = compression_decode_buffer(dstBuffer, dstCapacity,
                                                        srcPtr, srcSize,
                                                        nil,
                                                        COMPRESSION_ZLIB)
            if decodedSize == 0 { return nil }
            return Data(bytes: dstBuffer, count: decodedSize)
        }
    }
    
    func deflate() -> Data? {
        return self.withUnsafeBytes { (src: UnsafeRawBufferPointer) -> Data? in
            guard let srcPtr = src.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return nil }
            let srcSize = self.count
            
            let dstCapacity = 10_000_000
            let dstBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCapacity)
            defer { dstBuffer.deallocate() }
            
            let encodedSize = compression_encode_buffer(dstBuffer, dstCapacity,
                                                        srcPtr, srcSize,
                                                        nil,
                                                        COMPRESSION_ZLIB)
            if encodedSize == 0 { return nil }
            return Data(bytes: dstBuffer, count: encodedSize)
        }
    }
}
