//
//  UnifyWalletApp.swift
//  UnifyWallet
//
//  Created by Peter Denton on 6/24/24.
//

import SwiftUI


@main
struct UnifyWalletApp: App {
    //@StateObject private var manager: DataManager = DataManager()
    @State private var showNotSavedAlert = false
    
    
    init() {
        createDefaultCreds()
    }
    

    var body: some Scene {
        WindowGroup {
            HomeView()
                //.environmentObject(manager)
                //.environment(\.managedObjectContext, manager.container.viewContext)
        }
    }
    
    
    private func createDefaultCreds() {
//        DataManager.deleteAllData(entityName: "RPCCredentials") { deleted in
//            print("deleted credentials: \(deleted)")
//        }
//        DataManager.deleteAllData(entityName: "BIP39Signer") { deleted in
//            print("deleted signers: \(deleted)")
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
                
                guard let rpcauthcreds = RPCAuth().generateCreds(username: "Unify", password: nil) else {
                    showNotSavedAlert = true
                    return
                }
                
                UserDefaults.standard.setValue("38332", forKey: "rpcPort")
                UserDefaults.standard.setValue("Signet", forKey: "network")
                
                let rpcpass = rpcauthcreds.password
                
                guard let encRpcPass = Crypto.encrypt(rpcpass.data(using: .utf8)!) else {
                    showNotSavedAlert = true
                    return
                }
                
                let dict: [String:Any] = [
                    "rpcPass": encRpcPass,
                    "rpcUser": "Unify"
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
