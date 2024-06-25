//
//  Signer.swift
//  Pay Join
//
//  Created by Peter Denton on 4/24/24.
//

import Foundation
import LibWally

class Signer {
    class func masterKey(words: String, chain: Network, passphrase: String) -> String? {
//        let networkSetting = UserDefaults.standard.object(forKey: "network") as? String ?? "Signet"
//        var chain: Network = .testnet
//        
//        if networkSetting == "Mainnet" {
//            chain = .mainnet
//        }
        
        if let mnmemonic = try? BIP39Mnemonic(words: words) {
            let seedHex = mnmemonic.seedHex(passphrase: passphrase)
            if let hdMasterKey = try? HDKey(seed: seedHex, network: chain), let xpriv = hdMasterKey.xpriv {
                return xpriv
            }
        }
        
        return nil
    }
    
    class func sign(psbt: String, passphrase: String?, completion: @escaping ((psbt: String?, rawTx: String?, errorMessage: String?)) -> Void) {
        var seedsToSignWith = [[String:Any]]()
        var xprvToSignWith: HDKey? = nil
        var psbtToSign: PSBT!
        var chain: Network!
        //var coinType: String!
        
        func reset() {
            seedsToSignWith.removeAll()
            xprvToSignWith = nil
            psbtToSign = nil
            chain = nil
        }
        
        func finalize() {
            // First we strip out the bip32derivs for privacy reasons.
            let paramDict:[String: Any] = [
                "psbt": psbtToSign.description,
                "bip32derivs": false
            ]
            
            let param = Wallet_Process_PSBT(paramDict)
            
            BitcoinCoreRPC.shared.btcRPC(method: .walletprocesspsbt(param: param)) { (object, errorDescription) in
                if let dict = object as? NSDictionary, let strippedPsbt = dict["psbt"] as? String {
                    let finalizeParam:Finalize_Psbt = .init(["psbt": strippedPsbt])
                    
                    BitcoinCoreRPC.shared.btcRPC(method: .finalizepsbt(finalizeParam)) { (object, errorDescription) in
                        if let result = object as? NSDictionary {
                            if let complete = result["complete"] as? Bool {
                                if complete {
                                    let hex = result["hex"] as! String
                                    reset()
                                    completion((strippedPsbt, hex, nil))
                                } else {
                                    reset()
                                    completion((strippedPsbt, nil, nil))
                                }
                            } else {
                                reset()
                                completion((nil, nil, errorDescription))
                            }
                        } else {
                            reset()
                            completion((nil, nil, errorDescription))
                        }
                    }
                }
            }
        }
        
        func processWithActiveWallet() {
            let paramDict:[String: Any] = [
                "psbt": psbtToSign.description
            ]
            
            let param = Wallet_Process_PSBT(paramDict)
            
            BitcoinCoreRPC.shared.btcRPC(method: .walletprocesspsbt(param: param)) { (object, errorDescription) in
                if let dict = object as? NSDictionary {
                    if let processedPsbt = dict["psbt"] as? String {
                        do {
                            psbtToSign = try PSBT(psbt: processedPsbt, network: chain)
                            if xprvToSignWith != nil {
                                attemptToSignLocally()
                            } else {
                                finalize()
                            }
                        } catch {
                            if xprvToSignWith != nil {
                                attemptToSignLocally()
                            } else {
                                finalize()
                            }
                        }
                    }
                } else {
                    reset()
                    completion((nil, nil, errorDescription))
                }
            }
        }
        
        func attemptToSignLocally() {
            /// Need to ensure similiar seeds do not sign mutliple times. This can happen if a user adds the same seed multiple times.
            if xprvToSignWith != nil {
                var signableKeys = [String]()
                    let inputs = psbtToSign.inputs
                    for (x, input) in inputs.enumerated() {
                        /// Create an array of child keys that we know can sign our inputs.
                        if let origins: [PubKey : KeyOrigin] = input.canSignOrigins(with: xprvToSignWith!) {
                            for origin in origins {
                                if let childKey = try? xprvToSignWith!.derive(using: origin.value.path) {
                                    if let privKey = childKey.privKey {
                                        precondition(privKey.pubKey == origin.key)
                                        signableKeys.append(privKey.wif)
                                    }
                                }
                            }
                        } else {
                            // Libwally does not like signing with direct decendants of m (e.g. m/0/0), so if above fails we can try and fall back on this, deriving child keys directly from root xprv.
                            if let origins = input.origins {
                                for origin in origins {
                                    if let path = try? BIP32Path(string: origin.value.path.description.replacingOccurrences(of: "m/", with: "")) {
                                        if var childKey = try? xprvToSignWith!.derive(using: path) {
                                            if var privKey = childKey.privKey {
                                                signableKeys.append(privKey.wif)
                                                // Overwrite vars with dummies for security
                                                privKey = try! Key(wif: "KwfUAErbeHJCafVr37aRnYcobent1tVV1iADD2k3T8VV1pD2qpWs", network: .mainnet)
                                                childKey = try! HDKey(base58: "xpub6FETvV487Sr4VSV9Ya5em5ZAug4dtnFwgnMG7TFAfkJDHoQ1uohXft49cFenfpJHbPueMnfyxtBoAuvSu7XNL9bbLzcM1QJCPwtofqv3dqC")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        /// Once the above loops complete we remove any duplicate signing keys from the array then sign the psbt with each unique key.
                        if x + 1 == inputs.count {
                            var uniqueSigners = Array(Set(signableKeys))
                            if uniqueSigners.count > 0 {
                                for (s, signer) in uniqueSigners.enumerated() {
                                    if var signingKey = try? Key(wif: signer, network: chain) {
                                        psbtToSign = try? psbtToSign.signed(with: signingKey)//psbtToSign.sign(signingKey)
                                        signingKey = try! Key(wif: "KwfUAErbeHJCafVr37aRnYcobent1tVV1iADD2k3T8VV1pD2qpWs", network: .mainnet)
                                        /// Once we completed the signing loop we finalize with our node.
                                        if s + 1 == uniqueSigners.count {
                                            xprvToSignWith = nil
                                            uniqueSigners.removeAll()
                                            signableKeys.removeAll()
                                            finalize()
                                        }
                                    }
                                }
                            } else {
                                xprvToSignWith = nil
                                uniqueSigners.removeAll()
                                signableKeys.removeAll()
                                finalize()
                            }
                        }
                    }
            } else {
                finalize()
            }
        }
        
        /// Fetch wallets on the same network
        func getSeeds() {
            seedsToSignWith.removeAll()
            DataManager.retrieveSigners() { signers in
                guard let signers = signers else {
                    print("no signer")
                    return
                }
                
                for signer in signers {
                    
                    guard let encryptedSigner = signer["encryptedData"] as? Data else {
                        print("no encryptedSigner")
                        return
                    }
                    
                    
                    if var seed = Crypto.decrypt(encryptedSigner) {
                        if var words = String(data: seed, encoding: .utf8) {
                            seed = Data()
                            
                            if var masterKey = masterKey(words: words, chain: chain, passphrase: "") {
                                words = ""
                                if var hdkey = try? HDKey(base58: masterKey) {
                                    masterKey = ""
                                    xprvToSignWith = hdkey
                                    hdkey = try! HDKey(base58: "xpub6FETvV487Sr4VSV9Ya5em5ZAug4dtnFwgnMG7TFAfkJDHoQ1uohXft49cFenfpJHbPueMnfyxtBoAuvSu7XNL9bbLzcM1QJCPwtofqv3dqC")
                                    processWithActiveWallet()
                                    break
                                }
                            }
                        }
                    } else {
                        print("decrypting signer failed")
                    }
                }
            }
        }
        
        let networkSetting = UserDefaults.standard.object(forKey: "network") as? String ?? "Signet"
        chain = .testnet
        
        if networkSetting == "Mainnet" {
            chain = .mainnet
        }
        
        do {
            psbtToSign = try PSBT(psbt: psbt, network: chain)
            if psbtToSign.isComplete {
                finalize()
            } else {
                getSeeds()
            }
        } catch {
            completion((nil, nil, "Error converting that psbt"))
        }
        
    }
}

