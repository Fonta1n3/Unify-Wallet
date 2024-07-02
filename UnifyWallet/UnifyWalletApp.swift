//
//  UnifyWalletApp.swift
//  UnifyWallet
//
//  Created by Peter Denton on 6/24/24.
//

import SwiftUI

@main
struct UnifyWalletApp: App {
    @StateObject private var manager: DataManager = DataManager()
    @State private var showNotSavedAlert = false
    @State private var showSavedAlert = false
    
    
    init() {
        createDefaultCreds()
    }
    

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(manager)
                .environment(\.managedObjectContext, manager.container.viewContext)
        }
    }
    
    
    private func createDefaultCreds() {
        DispatchQueue.global(qos: .background).async {
            DataManager.retrieve(entityName: "Credentials") { credentials in
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
                    
                    saveCreds(dict: dict)
                    
                    return
                }
            }
        }
    }
    
    
    private func saveCreds(dict: [String: Any]) {
        DataManager.saveEntity(entityName: "Credentials", dict: dict) { saved in
            guard saved else {
                showNotSavedAlert = true
                return
            }
            
            showSavedAlert = true
        }
    }
}
