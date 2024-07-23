//
//  UnifyWalletApp.swift
//  UnifyWallet
//
//  Created by Peter Denton on 6/24/24.
//

import SwiftUI


@main
struct UnifyWalletApp: App {
    @State private var showNotSavedAlert = false
    
    
    init() {
        createDefaultCreds()
    }
    

    var body: some Scene {
        WindowGroup {
            HomeView()
            #if os(iOS)
                .onAppear(perform: UIApplication.shared.addTapGestureRecognizer)
            #endif
        }
    }
    
    
    private func createDefaultCreds() {
//        DataManager.deleteAllData(entityName: "RPCCredentials") { deleted in
//            print("deleted credentials: \(deleted)")
//        }
//        DataManager.deleteAllData(entityName: "BIP39Signer") { deleted in
//            print("deleted signers: \(deleted)")
//        }
//        DataManager.deleteAllData(entityName: "TorCredentials") { deleted in
//            print("deleted tor credentials: \(deleted)")
//        }
        
        
        DispatchQueue.global(qos: .background).async {
            createDefaultRPCCreds()
        }
    }
    
    
    private func createDefaultRPCCreds() {
        DataManager.retrieve(entityName: "RPCCredentials") { credentials in
            guard let _ = credentials else {
                
                let randomKey = random_bytes(count: 5).hex
                UserDefaults.standard.setValue(randomKey, forKey: "encKeyUnify")
                
                guard KeyChain.set(Crypto.privKeyData(), forKey: randomKey) else {
                    showNotSavedAlert = true
                    return
                }
                
                // MARK: Normal flow
//                UserDefaults.standard.setValue("38332", forKey: "rpcPort")
//                UserDefaults.standard.setValue("Signet", forKey: "network")
//                                
//                guard let encRpcPass = Crypto.encrypt(Crypto.privKeyData()) else {
//                    showNotSavedAlert = true
//                    return
//                }
//                
//                let dict: [String:Any] = [
//                    "rpcPass": encRpcPass,
//                    "rpcUser": "Unify",
//                    "rpcAddress": "127.0.0.1",
//                    "rpcPort": "38332"
//                ]
                
                // MARK: Demo mode
                guard let rpcauthcreds = RPCAuth().generateCreds(username: "Unify", password: "1d52e89e0c16a7cc57cbda4954eebf4ba7864e113e5c8bbaa8ab662c8af9ce91") else {
                    showNotSavedAlert = true
                    return
                }
                
                UserDefaults.standard.setValue("38332", forKey: "rpcPort")
                UserDefaults.standard.setValue("Signet", forKey: "network")
                UserDefaults.standard.setValue(true, forKey: "torEnabled")
                UserDefaults.standard.setValue("FullyNoded-da09e4c7b0fc6187c2c1bd2ace56bad7ba25406da168d7b16b4793ef81a082f9", forKey: "walletName")
                // Specify a wallet too.
                
                let rpcpass = rpcauthcreds.password
                
                guard let encRpcPass = Crypto.encrypt(rpcpass.data(using: .utf8)!) else {
                    showNotSavedAlert = true
                    return
                }
                
                let dict: [String:Any] = [
                    "rpcPass": encRpcPass,
                    "rpcUser": "Unify",
                    "rpcAddress": "rarokrtgsiwy42pcgmrp2sdslrt2efpt56rbhjvnwjnje2os64p3t5qd.onion",
                    "rpcPort": "38332"
                ]
                                
                let d = Data("smile pool offer seat betray sponsor build genius vault follow glad near".utf8)
                guard let encryptedSigner = Crypto.encrypt(d) else { return }
                DataManager.saveEntity(entityName: "BIP39Signer", dict: ["encryptedData": encryptedSigner]) { signerSaved in
                    guard signerSaved else { return }
                    
                    saveCreds(entityName: "RPCCredentials", dict: dict)
                    
                    createDefaultTorCreds()
                }
                
                return
            }
        }
    }
    
    
    private func createDefaultTorCreds() {
        DataManager.retrieve(entityName: "TorCredentials") { dict in
            guard let _ = dict else {
                let torAuthKeyPair = Crypto.torAuthKeypair()
                
                guard let encryptedPrivateKeyData = Crypto.encrypt(torAuthKeyPair.privateKey) else {
                    showNotSavedAlert = true
                    return
                }
                
                let dict: [String: Any] = [
                    "encryptedPrivateKey": encryptedPrivateKeyData,
                    "publicKey": torAuthKeyPair.publicKey
                ]
                
                saveCreds(entityName: "TorCredentials", dict: dict)
                
                return
            }
        }
    }
    
    
    private func saveCreds(entityName: String, dict: [String: Any]) {
        DataManager.saveEntity(entityName: entityName, dict: dict) { saved in
            guard saved else {
                showNotSavedAlert = true
                return
            }
        }
    }
}

#if os(iOS)
extension UIApplication {
    func addTapGestureRecognizer() {
        guard let window = windows.first else { return }
        let tapGesture = UITapGestureRecognizer(target: window, action: #selector(UIView.endEditing))
        tapGesture.requiresExclusiveTouchType = false
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        window.addGestureRecognizer(tapGesture)
    }
}

extension UIApplication: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true // set to `false` if you don't want to detect tap during other gestures
    }
}
#endif
