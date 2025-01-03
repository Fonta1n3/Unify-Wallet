//
//  Crypto.swift
//  Pay Join
//
//  Created by Peter Denton on 2/11/24.
//

import Foundation
import secp256k1
import CryptoKit
import LibWally

class Crypto {
    
    static let encKeyUnify = UserDefaults.standard.value(forKey: "encKeyUnify") as? String
    
    static func encrypt(_ data: Data) -> Data? {
        guard let encKeyUnify = encKeyUnify else { return nil }
        
        guard let key = KeyChain.getData(encKeyUnify) else {
            if KeyChain.set(Crypto.privKeyData(), forKey: encKeyUnify) {
                return encrypt(data)
            } else {
                return nil
            }
        }
        
        return try? ChaChaPoly.seal(data, using: SymmetricKey(data: key)).combined
    }
    
    
    static func decrypt(_ data: Data) -> Data? {
        guard let encKeyUnify = encKeyUnify else { return nil }
        
        guard let key = KeyChain.getData(encKeyUnify),
            let box = try? ChaChaPoly.SealedBox.init(combined: data) else {
                return nil
        }
        
        return try? ChaChaPoly.open(box, using: SymmetricKey(data: key))
    }
    
    
    static func sha256hash(_ data: Data) -> Data {
        let digest = SHA256.hash(data: data)
        
        return Data(digest)
    }
    
    
    static func sha256hash(_ text: String) -> String {
        let digest = SHA256.hash(data: Data(text.utf8))
        
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    
    static func seed() -> String? {
        var words: String?
        let bytesCount = 32
        var randomBytes = [UInt8](repeating: 0, count: bytesCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)
        
        if status == errSecSuccess {
            var data = Crypto.sha256hash(Crypto.sha256hash(Crypto.sha256hash(Data(randomBytes))))
            data = data.subdata(in: Range(0...15))
            let entropy = BIP39Mnemonic.Entropy(data)
            if let mnemonic = try? BIP39Mnemonic(entropy: entropy) {
                words = mnemonic.description
            }
        }
        
        return words
    }

    
    static var randomPubKey: String {
        let privateKey = try! secp256k1.KeyAgreement.PrivateKey()
        return privateKey.publicKey.dataRepresentation.hex
    }
    
    
    static var privKeyHex: String {
        return privKeyData().hex
    }
    
    
    static func privKeyData() -> Data {
        return try! secp256k1.KeyAgreement.PrivateKey().rawRepresentation
    }
    
    
    static func torAuthKeypair() -> (privateKey: Data, publicKey: String) {
        let privKeyRaw = Curve25519.KeyAgreement.PrivateKey.init()
        let pubKeyRaw = privKeyRaw.publicKey
        
        let privKeyData = privKeyRaw.rawRepresentation
        let pubkeyData = pubKeyRaw.rawRepresentation
        
        let privkeyBase32 = privKeyData.base32EncodedString
        let pubkeyBase32 = pubkeyData.base32EncodedString
        
        let privKey = privkeyBase32.replacingOccurrences(of: "====", with: "")
        let pubKey = pubkeyBase32.replacingOccurrences(of: "====", with: "")
        
        return ((Data(privKey.utf8), pubKey))
    }
}
