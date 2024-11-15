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
        }
    }
    
    
    private func createDefaultCreds() {
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
                UserDefaults.standard.setValue("8332", forKey: "rpcPort")
                UserDefaults.standard.setValue("Mainnet", forKey: "network")
                                
                guard let encRpcPass = Crypto.encrypt(Crypto.privKeyData()) else {
                    showNotSavedAlert = true
                    return
                }
                
                let dict: [String:Any] = [
                    "rpcPass": encRpcPass,
                    "rpcUser": "Unify",
                    "rpcAddress": "127.0.0.1",
                    "rpcPort": "8332"
                ]
                
                saveCreds(entityName: "RPCCredentials", dict: dict)
                createDefaultTorCreds()
               
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
