//
//  Keys.swift
//  UnifyWallet
//
//  Created by Peter Denton on 7/1/24.
//

import Foundation
import LibWally


enum Keys {
    
    static func donationAddress() -> String? {
        let randomInt = Int.random(in: 0..<100)
        
        
        
        let networkSetting = UserDefaults.standard.object(forKey: "network") as? String ?? "Signet"
        var network: Network = .testnet
        
        if networkSetting == "Mainnet" {
            network = .mainnet
        }
        
        guard let hdKey = try? HDKey(base58: "xpub6C1DcRZo4RfYHE5F4yiA2m26wMBLr33qP4xpVdzY1EkHyUdaxwHhAvAUpohwT4ajjd1N9nt7npHrjd3CLqzgfbEYPknaRW8crT2C9xmAy3G"),
            let path = try? BIP32Path(string: "0/\(randomInt)"),
              let address = try? hdKey.derive(using: path).address(type: .payToWitnessPubKeyHash), let x = try? Address(scriptPubKey: address.scriptPubKey, network: network) else { return nil }
        
        return x.description
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
    
    
    static func descriptorFromSigner(words: String, passphrase: String) -> (descriptors: String?, errorMess: String?) {
        let chain = UserDefaults.standard.object(forKey: "network") as? String ?? "Signet"
        
        var cointType = "0"
        
        if chain != "Mainnet" {
            cointType = "1"
        }
        
        guard let mk = Keys.masterKey(words: words, coinType: cointType, passphrase: passphrase),
              let xfp = Keys.fingerprint(masterKey: mk),
              let bip84Xpub = Keys.bip84AccountXpub(masterKey: mk, coinType: cointType, account: 0) else {
            return (nil, "Error deriving descriptors.")
        }
        
        let bip84 = "wpkh([\(xfp)/84h/\(cointType)h/0h]\(bip84Xpub)/0/*)"
        
        return (bip84, nil)
    }
    
    
    static func masterKey(words: String, coinType: String, passphrase: String) -> String? {
        let chain: Network
        
        if coinType == "0" {
            chain = .mainnet
        } else {
            chain = .testnet
        }
        
        if let mnmemonic = try? BIP39Mnemonic(words: words) {
            let seedHex = mnmemonic.seedHex(passphrase: passphrase)
            if let hdMasterKey = try? HDKey(seed: seedHex, network: chain), let xpriv = hdMasterKey.xpriv {
                return xpriv
            }
        }
        
        return nil
    }
    
    
    static func fingerprint(masterKey: String) -> String? {
        guard let hdMasterKey = try? HDKey(base58: masterKey) else { return nil }
        
        return hdMasterKey.fingerprint.hex
    }
    
    
    static func bip84AccountXpub(masterKey: String, coinType: String, account: Int16) -> String? {
        guard let hdMasterKey = try? HDKey(base58: masterKey),
            let path = try? BIP32Path(string: "m/84h/\(coinType)h/\(account)h"),
            let accountKey = try? hdMasterKey.derive(using: path) else { return nil }
        
        return accountKey.xpub
    }
}


