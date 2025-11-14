import Foundation
import CommonCrypto

public enum AES256Helper {
    
    public static func encrypt(data: Data, key: Data, iv: Data) -> Data? {
        var outLength = 0
        var outBytes = [UInt8](repeating: 0, count: data.count + kCCBlockSizeAES128)
        
        let status = CCCrypt(CCOperation(kCCEncrypt),
                             CCAlgorithm(kCCAlgorithmAES),
                             CCOptions(kCCOptionPKCS7Padding),
                             [UInt8](key),
                             kCCKeySizeAES256,
                             [UInt8](iv),
                             [UInt8](data),
                             data.count,
                             &outBytes,
                             outBytes.count,
                             &outLength)
        guard status == kCCSuccess else { return nil }
        return Data(bytes: outBytes, count: outLength)
    }
    
    public static func decrypt(data: Data, key: Data, iv: Data) -> Data? {
        var outLength = 0
        var outBytes = [UInt8](repeating: 0, count: data.count + kCCBlockSizeAES128)
        
        let status = CCCrypt(CCOperation(kCCDecrypt),
                             CCAlgorithm(kCCAlgorithmAES),
                             CCOptions(kCCOptionPKCS7Padding),
                             [UInt8](key),
                             kCCKeySizeAES256,
                             [UInt8](iv),
                             [UInt8](data),
                             data.count,
                             &outBytes,
                             outBytes.count,
                             &outLength)
        guard status == kCCSuccess else { return nil }
        return Data(bytes: outBytes, count: outLength)
    }
}

