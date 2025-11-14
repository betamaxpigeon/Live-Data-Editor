import Foundation
import CryptoHelpers
import CipherLogic
import Base64Logic
import AES256Logic
import XChaChaPolyLogic
import RSALogic

final class CipherManager {

    static let shared = CipherManager()
    private let generalSettings = GeneralSettings.shared

    // MARK: - Encrypt
    func encrypt(data: Data, key: Data? = nil, iv: Data? = nil, publicKey: Data? = nil) -> Data? {
        switch generalSettings.selectedCipher {
        case "AES256":
            guard let key = key, let iv = iv else { return nil }
            return Crypto.aesCBCEncrypt(data: data, key: key, iv: iv)
        case "XChaChaPoly":
            guard let key = key else { return nil }
            return XChaChaPolyHelper.encrypt(data: data, key: key)
        case "RSA":
            guard let publicKey = publicKey else { return nil }
            return RSAHelper.encrypt(data: data, publicKey: publicKey)
        case "Base64":
            return Codec.encode(data)
        case "None":
            return nil
        default:
            return nil
        }
    }

    // MARK: - Decrypt
    func decrypt(data: Data, key: Data? = nil, iv: Data? = nil, privateKey: Data? = nil) -> Data? {
        switch generalSettings.selectedCipher {
        case "AES256":
            guard let key = key, let iv = iv else { return nil }
            return Crypto.aesCBCDecrypt(data: data, key: key, iv: iv)
        case "XChaChaPoly":
            guard let key = key else { return nil }
            return XChaChaPolyHelper.decrypt(data: data, key: key)
        case "RSA":
            guard let privateKey = privateKey else { return nil }
            return RSAHelper.decrypt(data: data, privateKey: privateKey)
        case "Base64":
            return Codec.decode(data)
        case "None":
            return nil
        default:
            return nil
        }
    }
}
