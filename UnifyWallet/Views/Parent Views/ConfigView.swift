//
//  ConfigView.swift
//  Pay Join
//
//  Created by Peter Denton on 2/13/24.
//

import SwiftUI
import UniformTypeIdentifiers
import NostrSDK
import LibWally

struct ConfigView: View {
    @State private var rpcUser = "Unify"
    @State private var rpcPassword = ""
    @State private var rpcAuth = ""
    @State private var rpcWallet = ""
    @State private var rpcWallets: [String] = []
    @State private var rpcPort = UserDefaults.standard.object(forKey: "rpcPort") as? String ?? "38332"
    @State private var nostrRelay = UserDefaults.standard.object(forKey: "nostrRelay") as? String ?? "wss://relay.damus.io"
    @State private var showBitcoinCoreError = false
    @State private var bitcoinCoreError = ""
    @State private var showNoCredsError = false
    @State private var showInvalidSignerError = false
    @State private var encSigner = ""
    @State private var bitcoinCoreConnected = false
    @State private var tint: Color = .red
    @State private var chain = UserDefaults.standard.object(forKey: "network") as? String ?? "Signet"
    
    let chains = ["Mainnet", "Signet", "Testnet", "Regtest"]
    
    
    var body: some View {
        Spacer()
        Label("Configuration", systemImage: "gear")
        
        Form() {
            Section("Bitcoin Core") {
                HStack() {
                    Label("Bitcoin Core Status", systemImage: "server.rack")
                    
                    Spacer()
                    
                    Image(systemName: "circle.fill")
                        .foregroundColor(tint)
                    
                    if bitcoinCoreConnected {
                        Text("Connected")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Disconnected")
                            .foregroundStyle(.secondary)
                    }
                    
                    Button {
                        setValues()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                
                if !bitcoinCoreConnected {
                    Text(bitcoinCoreError)
                        .foregroundStyle(.tertiary)
                }
                
                HStack() {
                    Label("Network", systemImage: "network")
                    
                    Spacer()
                                        
                    Picker("", selection: $chain) {
                        ForEach(chains, id: \.self) {
                            Text($0)
                                .tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: chain) {
                        print("update network to \(chain)")
                        
                        switch chain {
                        case "Mainnet": rpcPort = "8332"
                        case "Signet": rpcPort = "38332"
                        case "Testnet": rpcPort = "18332"
                        case "Regtest": rpcPort = "18443"
                        default:
                            break
                        }
                        
                        UserDefaults.standard.setValue(chain, forKey: "network")
                        updateRpcPort()
                    }
                }
            }
            
            Section("RPC Credentials") {
                HStack() {
                    Label("RPC User", systemImage: "person.circle")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    TextField("", text: $rpcUser)
                        .onChange(of: rpcUser) {
                            updateRpcUser(rpcUser: rpcUser)
                        }
                }
                
                HStack() {
                    Label("RPC Password", systemImage: "ellipsis.rectangle.fill")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    SecureField("", text: $rpcPassword)
                        .onChange(of: rpcPassword) {
                            updateRpcPass(rpcPass: rpcPassword)
                        }
                    
                    Button {
                        rpcPassword = Crypto.privKeyHex
                        updateRpcPass(rpcPass: rpcPassword)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                
                HStack() {
                    Label("RPC Port", systemImage: "network")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    TextField("", text: $rpcPort)
                        .onChange(of: rpcPort) {
                            updateRpcPort()
                        }
                    #if os(iOS)
                        .keyboardType(.numberPad)
                    #endif
                }
                
                HStack() {
                    Label("RPC Authentication", systemImage: "key.horizontal.fill")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    CopyView(item: rpcAuth)
                }
                
                Text("Copy the rpcauth text and add it to your bitcoin.conf to authorize Unify to communicate with your node.")
                    .foregroundStyle(.tertiary)
            }
            
            Section("RPC Wallet") {
                if rpcWallet == "" {
                    Label("No wallet selected", systemImage: "wallet.pass")
                        .foregroundStyle(.red)
                } else {
                    Label(rpcWallet, systemImage: "wallet.pass")
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                if rpcWallets.count == 0 {
                    Text("No wallets...")
                        .foregroundStyle(.secondary)
                }
                
                Picker("Select wallet", selection: $rpcWallet) {
                    ForEach(rpcWallets, id: \.self) { wallet in
                        Text(wallet)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .tag(wallet)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: rpcWallet) {
                    UserDefaults.standard.setValue(rpcWallet, forKey: "walletName")
                }
                
                Text("Select a wallet to use. In Fully Noded you can see the wallet filename in the Wallet Info view. Unify works with BIP84 only for now (native segwit) as mixing input and output types is bad for privacy.")
                    .foregroundStyle(.tertiary)
            }
            
            Section("Nostr") {
                HStack() {
                    Label("Relay URL", systemImage: "server.rack")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    TextField("", text: $nostrRelay)
                        .onChange(of: nostrRelay) {
                            updateNostrRelay()
                        }
                }
            }
            
            Section("Signer") {
                HStack() {
                    Label("BIP39 Menmonic", systemImage: "signature")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    SecureField("", text: $encSigner)
                    
                    Button("Save") {
                        updateSigner()
                    }
                }
                
                Text("Your signer is encrypted before being saved.")
                    .foregroundStyle(.tertiary)
            }
        }
        .autocorrectionDisabled()
        .formStyle(.grouped)
        .multilineTextAlignment(.leading)
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
        
        .onSubmit {
            rpcWallets.removeAll()
        }
        
        .onAppear {
            setValues()
        }
        
        .alert(bitcoinCoreError, isPresented: $showBitcoinCoreError) {
            Button("OK", role: .cancel) {}
        }
        
        .alert(CoreDataError.notPresent.localizedDescription, isPresented: $showNoCredsError) {
            Button("OK", role: .cancel) {}
        }
        
        .alert("Invalid BIP39 Mnemonic.", isPresented: $showInvalidSignerError) {
            Button("OK", role: .cancel) {}
        }
    }
    
    
    private func setValues() {
        rpcWallets.removeAll()
        rpcWallet = ""
        
        DataManager.retrieve(entityName: "Signers") { signer in
            guard let signer = signer, let encSignerData = signer["encryptedData"] as? Data else {
                return
            }
            
            encSigner = encSignerData.hex
        }
        
        DataManager.retrieve(entityName: "Credentials", completion: { credentials in
            guard let credentials = credentials else {
                showNoCredsError = true
                return
            }
            
            guard let encRpcPass = credentials["rpcPass"] as? Data else {
                return
            }
            
            guard let rpcPassData = Crypto.decrypt(encRpcPass) else { print("unable to decrypt rpcpass")
                return
            }
            
            guard let rpcPass = String(data: rpcPassData, encoding: .utf8) else {
                return
            }
            
            chain = UserDefaults.standard.object(forKey: "network") as? String ?? "Signet"
            
            rpcPassword = rpcPass
            
            guard let savedRpcUser = credentials["rpcUser"] as? String else {
                return
            }
            
            rpcUser = savedRpcUser
            
            guard let rpcauthcreds = RPCAuth().generateCreds(username: savedRpcUser, password: rpcPass) else {
                return
            }
            
            rpcAuth = rpcauthcreds.rpcAuth
            
            if let walletName = UserDefaults.standard.object(forKey: "walletName") as? String {
                rpcWallet = walletName
            }
            
            rpcPort = UserDefaults.standard.object(forKey: "rpcPort") as? String ?? "38332"
            nostrRelay = UserDefaults.standard.object(forKey: "nostrRelay") as? String ?? "wss://relay.damus.io"
            
            BitcoinCoreRPC.shared.btcRPC(method: .listwallets) { (response, errorDesc) in
                guard errorDesc == nil else {
                    bitcoinCoreError = errorDesc!
                    return
                }
                
                guard let wallets = response as? [String] else {
                    bitcoinCoreError = BitcoinCoreError.noWallets.localizedDescription
                    return
                }
                
                bitcoinCoreConnected = true
                tint = .green
                
                guard wallets.count > 0 else {
                    bitcoinCoreError = "No wallets exist yet..."
                    return
                }
                
                rpcWallets = wallets
            }
        })
    }
    
    
    private func updateRpcUser(rpcUser: String) {
        DataManager.update(entityName: "Credentials", keyToUpdate: "rpcUser", newValue: rpcUser) { updated in
            if updated {
                self.rpcUser = rpcUser
                updateRpcAuth()
            }
        }
    }
    
    
    private func updateRpcPass(rpcPass: String) {
        guard let rpcPassData = rpcPass.data(using: .utf8) else {
            return
        }
        
        guard let encryptedRpcPass = Crypto.encrypt(rpcPassData) else {
            return
        }
        
        DataManager.update(entityName: "Credentials", keyToUpdate: "rpcPass", newValue: encryptedRpcPass) { updated in
            if updated {
                self.rpcPassword = rpcPass
                updateRpcAuth()
            }
        }
    }
    
    
    private func updateRpcAuth() {
        guard let rpcauthcreds = RPCAuth().generateCreds(username: rpcUser, password: rpcPassword) else {
            return
        }
        
        rpcAuth = rpcauthcreds.rpcAuth
    }
    
    
    private func updateRpcPort() {
        UserDefaults.standard.setValue(rpcPort, forKey: "rpcPort")
    }
    
    
    private func updateNostrRelay() {
        UserDefaults.standard.setValue(nostrRelay, forKey: "nostrRelay")
    }
    
    
    private func updateSigner() {
        // Display an alert that its valid and saved
        let words = encSigner.components(separatedBy: " ")
        var wordsNoSpaces: [String] = []
        
        for word in words {
            wordsNoSpaces.append(word.noWhiteSpace)
        }
        
        guard let _ = try? BIP39Mnemonic(words: wordsNoSpaces) else {
            encSigner = ""
            showInvalidSignerError = true
            return
        }
        
        guard let encSeed = Crypto.encrypt(encSigner.data(using: .utf8)!) else {
            return
        }
        
        let dict: [String: Any] = ["encryptedData": encSeed]
        
        DataManager.saveEntity(entityName: "Signers", dict: dict) { saved in
            guard saved else {
                return
            }
            
            encSigner = encSeed.hex
        }
    }
}

struct CopyView: View {
    @State private var copied = false
    
    let item: String
    
    var body: some View {
        HStack() {
            Text(item)
                .truncationMode(.middle)
                .lineLimit(1)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.secondary)
                                    
            Button {
                #if os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item, forType: .string)
                #elseif os(iOS)
                UIPasteboard.general.string = item
                #endif
                copied = true
                
            } label: {
                Image(systemName: "doc.on.doc")
            }
            
            .alert("Copied", isPresented: $copied) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}
