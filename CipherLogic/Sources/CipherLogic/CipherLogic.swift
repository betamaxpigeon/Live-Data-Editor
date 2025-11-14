import Foundation
import CryptoKit
import CommonCrypto
import Security
import AES256Logic
import XChaChaPolyLogic
import RSALogic
import Base64Logic

public final class CipherLogic {

    @MainActor public static let shared = CipherLogic()

  var selectedCipher: String = GeneralSettings.shared.selectedCipher

    private init() {}

    // MARK: - Encrypt
    public func encrypt(data: Data, key: Data? = nil, iv: Data? = nil, publicKey: Data? = nil) -> Data? {
        switch selectedCipher {
        case "AES256":
            guard let key = key, let iv = iv else { return nil }
            return AES256Helper.encrypt(data: data, key: key, iv: iv)
        case "XChaChaPoly":
            guard #available(macOS 10.15, *) else { return nil }
            guard let key = key else { return nil }
            return XChaChaPolyHelper.encrypt(data: data, key: key)
        case "RSA":
            guard let publicKey = publicKey else { return nil }
            return RSAHelper.encrypt(data: data, publicKey: publicKey)
        case "Base64":
            return Codec.encode(data)
        case "Hollow Knight":
            guard let key = key, let iv = iv else { return nil }
            guard let deflated = try? Codec.deflate(data),
                  let encrypted = AES256Helper.encrypt(data: deflated, key: key, iv: iv)
            else { return nil }
            return Codec.encode(encrypted)
        default:
            return nil
        }
    }

    // MARK: - Decrypt
    public func decrypt(data: Data, key: Data? = nil, iv: Data? = nil, privateKey: Data? = nil) -> Data? {
        switch selectedCipher {
        case "AES256":
            guard let key = key, let iv = iv else { return nil }
            return AES256Helper.decrypt(data: data, key: key, iv: iv)
        case "XChaChaPoly":
            guard #available(macOS 10.15, *) else { return nil }
            guard let key = key else { return nil }
            return XChaChaPolyHelper.decrypt(data: data, key: key)
        case "RSA":
            guard let privateKey = privateKey else { return nil }
            return RSAHelper.decrypt(data: data, privateKey: privateKey)
        case "Base64":
            return Codec.decode(data)
        case "Hollow Knight":
            guard let key = key, let iv = iv else { return nil }
            let decoded = Codec.decode(data)
            guard let decrypted = AES256Helper.decrypt(data: decoded, key: key, iv: iv),
                  let inflated = try? Codec.inflate(decrypted)
            else { return nil }
            return inflated
        default:
            return nil
        }
    }
}
