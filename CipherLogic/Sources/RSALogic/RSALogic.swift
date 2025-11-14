import Foundation
import Security

public enum RSAHelper {

    public static func encrypt(data: Data, publicKey: Data) -> Data? {
        guard let key = createSecKey(from: publicKey, isPublic: true) else { return nil }
        var error: Unmanaged<CFError>?
        guard let cipherData = SecKeyCreateEncryptedData(key,
                                                         .rsaEncryptionOAEPSHA256,
                                                         data as CFData,
                                                         &error) as Data? else { return nil }
        return cipherData
    }

    public static func decrypt(data: Data, privateKey: Data) -> Data? {
        guard let key = createSecKey(from: privateKey, isPublic: false) else { return nil }
        var error: Unmanaged<CFError>?
        guard let plainData = SecKeyCreateDecryptedData(key,
                                                        .rsaEncryptionOAEPSHA256,
                                                        data as CFData,
                                                        &error) as Data? else { return nil }
        return plainData
    }

    private static func createSecKey(from keyData: Data, isPublic: Bool) -> SecKey? {
        let options: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: isPublic ? kSecAttrKeyClassPublic : kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: keyData.count * 8,
            kSecReturnPersistentRef as String: true
        ]
        return SecKeyCreateWithData(keyData as CFData, options as CFDictionary, nil)
    }
}

