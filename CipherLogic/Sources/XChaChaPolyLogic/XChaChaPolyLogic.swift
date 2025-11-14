import Foundation
import CryptoKit

public enum XChaChaPolyHelper {

    @available(macOS 10.15, *)
    public static func encrypt(data: Data, key: Data) -> Data? {
        let symmetricKey = SymmetricKey(data: key)
        guard let sealedBox = try? ChaChaPoly.seal(data, using: symmetricKey) else { return nil }
        return sealedBox.combined
    }

    @available(macOS 10.15, *)
    public static func decrypt(data: Data, key: Data) -> Data? {
        let symmetricKey = SymmetricKey(data: key)
        guard let sealedBox = try? ChaChaPoly.SealedBox(combined: data) else { return nil }
        return try? ChaChaPoly.open(sealedBox, using: symmetricKey)
    }
}
