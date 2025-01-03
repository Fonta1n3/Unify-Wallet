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
//import Tor

struct ConfigView: View {
    let torManager = TorClient.sharedInstance

    @State private var rpcUser = "Unify"
    @State private var rpcPassword = ""
    @State private var rpcAuth = ""
    @State private var rpcWallet = ""
    @State private var rpcWallets: [String] = []
    @State private var rpcPort = UserDefaults.standard.object(forKey: "rpcPort") as? String ?? "8332"
    @State private var nostrRelay = UserDefaults.standard.object(forKey: "nostrRelay") as? String ?? "wss://relay.damus.io"
    @State private var showBitcoinCoreError = false
    @State private var bitcoinCoreError = ""
    @State private var showError = false
    @State private var errorDesc = ""
    @State private var encSigner = ""
    @State private var bitcoinCoreConnected = false
    @State private var tint: Color = .red
    @State private var chain = UserDefaults.standard.object(forKey: "network") as? String ?? "Mainnet"
    @State private var showingPassphraseAlert = false
    @State private var passphrase = ""
    @State private var passphraseConfirm = ""
    @State private var creatingWallet = false
    @State private var torEnabled = false
    @State private var torProgress = 0.0
    @State private var torConnected = false
    @State private var torDifficulties = false
    @State private var encryptedTorAuthKey = ""
    @State private var torAuthPubkey = ""
    @State private var rpcAddress = "127.0.0.1"
    @State private var fetching = false
    @State private var isShowingScanner = false
    @FocusState var isInputActive: Bool
    
    let chains = ["Mainnet", "Signet", "Testnet", "Regtest"]
    
    
    var body: some View {
        Form() {
            Section("Bitcoin Core") {
                HStack() {
                    Label("Status", systemImage: "server.rack")
                    
                    Spacer()
                    
                    if fetching {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Connecting...")
                            .foregroundStyle(.secondary)
                        
                        ProgressView()
                            .padding(.leading)
                        #if os(macOS)
                            .scaleEffect(0.5)
                        #endif
                        
                    } else {
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
                
                if !bitcoinCoreConnected {
                    Label {
                        Text(bitcoinCoreError)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }
            }
            
            Section("RPC Credentials") {
#if os(iOS)
                HStack() {
                    Label("Quick Connect", systemImage: "qrcode")
                    Spacer()
                    Button {
                        isShowingScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                    }
                    .sheet(isPresented: $isShowingScanner) {
                        CodeScannerView(codeTypes: [.qr], simulatedData: "", completion: handleScan)
                    }
                }
                
                
#endif
                
                
                HStack() {
                    Label("User", systemImage: "person.circle")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    TextField("", text: $rpcUser)
                        .onChange(of: rpcUser) {
                            updateRpcUser(rpcUser: rpcUser)
                        }
                }
                
                HStack() {
                    Label("Password", systemImage: "ellipsis.rectangle.fill")
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
                    Label("Port", systemImage: "network")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    TextField("", text: $rpcPort)
                        .onSubmit {
                            updateRpcPort()
                            setValues()
                            isInputActive = false
                        }
                        .onTapGesture {
                            isInputActive = false
                        }
                
#if os(iOS)
                        .keyboardType(.numberPad)
                        .focused($isInputActive)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                
                                Button("Done") {
                                    isInputActive = false
                                }
                            }
                        }
#endif
                }
                
                HStack() {
                    Label("Address", systemImage: "antenna.radiowaves.left.and.right.circle")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    TextField("", text: $rpcAddress)
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                        .onChange(of: rpcAddress) {
                            updateRpcAddress()
                        }
                }
                
                HStack() {
                    Label("Auth", systemImage: "key.horizontal.fill")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    //Spacer()
                    
                    Text(rpcAuth)
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                    
                    ShareLink(items: [rpcAuth])
                }
                
                
                
                
                
//                Text("Copy the auth text to add it to your bitcoin.conf. This will authorize Unify to communicate with your node.")
//                    .foregroundStyle(.secondary)
                
                Text("It is strongly recommended to use an onion address for your RPC address! Connect Tor and onion's will work. The only acception should be 127.0.0.1 which is your local computer or a LAN address.")
                    .foregroundStyle(.secondary)
            }
            
            Section("Tor") {
                if torEnabled && !torConnected {
                    ProgressView("Bootstrapping \(Int(torProgress))% complete…", value: torProgress, total: 100)
                }
                
                Toggle("Connect", isOn: $torEnabled)
                    .onChange(of: torEnabled) {
                        if torEnabled && torManager.state != .connected && torManager.state != .started {
                            torManager.start()
                        }
                        
                        if !torEnabled {
                            torManager.resign()
                            torConnected = false
                            torProgress = 0.0
                        }
                        
                        UserDefaults.standard.setValue(torEnabled, forKey: "torEnabled")
                    }
                    .onAppear {
                        torManager.showProgress = { progress in
                            torProgress = Double(progress)
                        }
                        
                        torManager.torConnected = { connected in
                            torConnected = connected
                        }
                    }
                
                HStack(spacing: 0) {
                    Label("Status", systemImage: "server.rack")
                        //.frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    if torConnected {
                        Label {
                            Text("Connected")
                        } icon: {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.green)
                        }
                    } else {
                        Label {
                            Text("Disconnected")
                        } icon: {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                //if torEnabled {
                    // Toggle("Add Auth", isOn: $)
                    // check if tor is running, if it is prompt user to quit tor then try again.
                    HStack() {
                        Label("Privkey", systemImage: "ellipsis.rectangle.fill")
                            .frame(maxWidth: 200, alignment: .leading)
                        
                        Spacer()
                        
                        SecureField("", text: $encryptedTorAuthKey)
                        
                        Button {
                            updateTorPrivkey()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    
                    HStack() {
                        Label("Pubkey", systemImage: "key")
                            .frame(maxWidth: 200, alignment: .leading)
                        
                        Spacer()
                        
                        CopyView(item: "descriptor:x25519:" + torAuthPubkey)
                    }
                //}
            }
            
            if bitcoinCoreConnected {
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
                        .foregroundStyle(.secondary)
                    
                    if !creatingWallet && bitcoinCoreConnected {
                        Button {
                            showingPassphraseAlert.toggle()
                        } label: {
                            Text("Create a wallet")
                        }
                        .buttonStyle(.borderedProminent)
                        .alert("Enter your passphrase", isPresented: $showingPassphraseAlert) {
                            SecureField("Enter your passphrase", text: $passphrase)
                                .foregroundStyle(.black)
                            
                            SecureField("Confirm passphrase", text: $passphraseConfirm)
                                .foregroundStyle(.black)
                            
                            Button {
                                if passphrase == passphraseConfirm {
                                    createWallet()
                                } else {
                                    showError(desc: "Passphrase mismatch, try again.")
                                }
                            } label: {
                                Text("Create Wallet")
                            }
                            
                            Button("Cancel", role: .cancel) {
                                passphrase = ""
                                passphraseConfirm = ""
                                showingPassphraseAlert.toggle()
                            }
                            
                        } message: {
                            Text("We will use the passphrase and the saved BIP39 mnemonic to create a new wallet, if no BIP39 mnemonic is saved we will create a new one.")
                        }
                    } else if bitcoinCoreConnected {
                        ProgressView("Creating wallet...")
                    }
                    
                    
                    Text("This will create a wallet from the BIP39 mnemonic you have added below and prompt you for a passphrase, if blank we will create a new BIP39 mnemonic and prompt you for a passphrase. The passphrase is never saved and you must remember it to sign transactions.")
                        .foregroundStyle(.secondary)
                }
                
                
                Section("Signer") {
                    HStack() {
                        Label("BIP39 Menmonic", systemImage: "signature")
                            .frame(maxWidth: 200, alignment: .leading)
                        
                        SecureField("", text: $encSigner)
                        
                        Button {
                            DataManager.retrieve(entityName: "BIP39Signer") { bip39Signer in
                                guard let _ = bip39Signer else { return }
                                
                                DataManager.deleteAllData(entityName: "BIP39Signer") { deleted in
                                    if deleted {
                                        self.encSigner = ""
                                    }
                                }
                            }
                            
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        
                        Button("Save") {
                            updateSigner()
                        }
                    }
                    
                    Text("Your signer is encrypted before being saved.")
                        .foregroundStyle(.secondary)
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
            if torManager.state == .connected {
                torConnected = true
            }
            setValues()
        }
        .alert(errorDesc, isPresented: $showError) {
            Button("OK", role: .cancel) {}
        }
    }
    
#if os(iOS)
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let result):
            QuickConnect.addNode(url: result.string) { (success, errorMessage) in
                setValues()
                showError(desc: "Node saved ✓")
            }
            
        case .failure(let error):
            showError(desc: error.localizedDescription)
        }
    }
#endif
    
    private func showError(desc: String) {
        errorDesc = desc
        showError = true
    }
    
    
    private func createWallet() {
        creatingWallet = true
        
        if encSigner != "" {
            // Use existing seed words
            guard let data = encSigner.hexadecimalData else {
                creatingWallet = false
                showError(desc: "Unable to convert encrypted signer to hex string.")
                
                return
            }
            
            guard let decrpytedWords = Crypto.decrypt(data),
                  let words = String(data: decrpytedWords, encoding: .utf8) else {
                creatingWallet = false
                showError(desc: "Unable to decrypt seed words.")
                
                return
            }
            
            createWalletFromWords(words: words, passphrase: passphrase)
        } else {
            guard let newSeedWords = Keys.seed() else {
                creatingWallet = false
                showError(desc: "Unable to create seed words.")
                
                return
            }
            
            createWalletFromWords(words: newSeedWords, passphrase: passphrase)
        }
    }
    
    
    private func createWalletFromWords(words: String, passphrase: String) {
        let wordsData = Data(words.utf8)
        
        guard let encryptedSigner = Crypto.encrypt(wordsData) else {
            creatingWallet = false
            showError(desc: "Unable to encrypt seed words.")
            
            return
        }
        
        DataManager.saveEntity(entityName: "BIP39Signer", dict: ["encryptedData": encryptedSigner]) { saved in
            guard saved else {
                creatingWallet = false
                showError(desc: "Unable to save encrypted seed words.")
                
                return
            }
            
            convertWordsToDesc(words: words, passphrase: passphrase)
        }
    }
    
    
    private func convertWordsToDesc(words: String, passphrase: String) {
        let (bip84Desc, errDesc) = Keys.descriptorFromSigner(words: words, passphrase: passphrase)
        
        guard let bip84Desc = bip84Desc else {
            creatingWallet = false
            showError(desc: "Error getting bip84desc: \(errDesc ?? "unknown error")")
            
            return
        }
        
        let accMap: [String: Any] = ["descriptor": bip84Desc, "blockheight": 0]
        
        CreateWallet.accountMap(accMap) { (success, errorDescription) in
            guard success else {
                creatingWallet = false
                showError(desc: "Error creating wallet: \(errorDescription ?? "unknown")")
                
                return
            }
                        
            creatingWallet = false
            showError(desc: "Wallet created! This is your bip39 mnemonic, make sure to save it safely or you may lose access to your funds!\n\n\(words)")
            self.passphrase = ""
            passphraseConfirm = ""
            setValues()
        }
    }
    
    
    private func setValues() {
        fetching = true
        rpcWallets.removeAll()
        rpcWallet = ""
        
        //torEnabled = UserDefaults.standard.object(forKey: "torEnabled") as? Bool ?? false
        
        DataManager.retrieve(entityName: "TorCredentials") { torCredDict in
            guard let torCredDict = torCredDict else { return }
            
            let torCreds = TorCreds(dictionary: torCredDict)
            encryptedTorAuthKey = torCreds.encryptedPrivateKey.hex
            torAuthPubkey = torCreds.publicKey
        }
        
        DataManager.retrieve(entityName: "BIP39Signer") { signer in
            guard let signer = signer, let encSignerData = signer["encryptedData"] as? Data else {
                
                return
            }
            
            encSigner = encSignerData.hex
        }
        
        DataManager.retrieve(entityName: "RPCCredentials", completion: { credentials in
            guard let credentials = credentials else {
                showError(desc: "No credentials saved, something is not right.")
                
                return
            }
            
            guard let encRpcPass = credentials["rpcPass"] as? Data else {
                showError(desc: "No rpc password saved.")
                
                return
            }
            
            guard let rpcPassData = Crypto.decrypt(encRpcPass) else { print()
                showError(desc: "Unable to decrypt rpcpass.")
                
                return
            }
            
            guard let rpcPass = String(data: rpcPassData, encoding: .utf8) else {
                showError(desc: "Unable to convert rpcpass data to string.")
                
                return
            }
            
            if let rpcAddress = credentials["rpcAddress"] as? String {
                torEnabled = rpcAddress.hasSuffix(".onion")
            }
            
            rpcAddress = credentials["rpcAddress"] as? String ?? "127.0.0.1"
            rpcPort = credentials["rpcPort"] as? String ?? "38332"
            
            chain = UserDefaults.standard.object(forKey: "network") as? String ?? "Signet"
            
            rpcPassword = rpcPass
            
            guard let savedRpcUser = credentials["rpcUser"] as? String else {
                showError(desc: "No rpcuser saved.")
                
                return
            }
            
            rpcUser = savedRpcUser
            
            guard let rpcauthcreds = RPCAuth().generateCreds(username: savedRpcUser, password: rpcPass) else {
                showError(desc: "Unable to generate rpcauth.")
                
                return
            }
            
            rpcAuth = rpcauthcreds.rpcAuth
            
            if let walletName = UserDefaults.standard.object(forKey: "walletName") as? String {
                rpcWallet = walletName
            }
                        
            nostrRelay = UserDefaults.standard.object(forKey: "nostrRelay") as? String ?? "wss://relay.damus.io"
            
            fetching = true
            
            BitcoinCoreRPC.shared.btcRPC(method: .listwallets) { (response, errorDesc) in
                fetching = false
                
                guard errorDesc == nil else {
                    bitcoinCoreError = errorDesc!
                    //showError(desc: errorDesc!)
                    
                    return
                }
                
                guard let wallets = response as? [String] else {
                    bitcoinCoreError = BitcoinCoreError.noWallets.localizedDescription
                    //showError(desc: BitcoinCoreError.noWallets.localizedDescription)
                    
                    return
                }
                
                bitcoinCoreConnected = true
                tint = .green
                
                guard wallets.count > 0 else {
                    bitcoinCoreError = "No wallets exist yet..."
                    //showError(desc: bitcoinCoreError)
                    
                    return
                }
                
                rpcWallets = wallets
            }
        })
    }
    
    
    private func updateRpcUser(rpcUser: String) {
        DataManager.update(keyToUpdate: "rpcUser", newValue: rpcUser, entity: "RPCCredentials") { updated in
            if updated {
                self.rpcUser = rpcUser
                updateRpcAuth()
            } else {
                showError(desc: "RPC user not updated.")
            }
        }
    }
    
    
    private func updateRpcPass(rpcPass: String) {
        guard let rpcPassData = rpcPass.data(using: .utf8) else {
            showError(desc: "Unable to convert rpc password data to string.")
            
            return
        }
        
        guard let encryptedRpcPass = Crypto.encrypt(rpcPassData) else {
            showError(desc: "Unable to encrypt rpcpassword data.")
            
            return
        }
        
        DataManager.update(keyToUpdate: "rpcPass", newValue: encryptedRpcPass, entity: "RPCCredentials") { updated in
            if updated {
                self.rpcPassword = rpcPass
                updateRpcAuth()
            } else {
                showError(desc: "RPC password not updated.")
            }
        }
    }
    
    
    private func updateRpcAuth() {
        guard let rpcauthcreds = RPCAuth().generateCreds(username: rpcUser, password: rpcPassword) else {
            showError(desc: "Unable to generate rpcauth.")
            
            return
        }
        
        rpcAuth = rpcauthcreds.rpcAuth
    }
    
    
    private func updateRpcPort() {
        DataManager.update(keyToUpdate: "rpcPort", newValue: rpcPort, entity: "RPCCredentials") { rpcPortUpdated in
            guard rpcPortUpdated else {
                showError(desc: "Unable to update RPC port.")
                
                return
            }
            setValues()
        }
    }
    
    
    private func updateTorPrivkey() {
        KeyGen().generate { (pubkey, privkey) in
            guard let encrypted = Crypto.encrypt(privkey.dataUsingUTF8StringEncoding) else { return }
            DataManager.update(keyToUpdate: "encryptedPrivateKey", newValue: encrypted, entity: "TORCredentials") { encryptedPrivateKeyUpdated in
                guard encryptedPrivateKeyUpdated else {
                    showError(desc: "Unable to update encryptedPrivateKey.")
                    
                    return
                }
                //setValues()
                DataManager.update(keyToUpdate: "publicKey", newValue: pubkey, entity: "TORCredentials") { publicKeyUpdated in
                    guard publicKeyUpdated else {
                        showError(desc: "Unable to update publicKey.")
                        
                        return
                    }
                    setValues()
                }
            }
        }
        
    }
    
    
    private func updateRpcAddress() {
        DataManager.update(keyToUpdate: "rpcAddress", newValue: rpcAddress, entity: "RPCCredentials") { rpcAddressUpdated in
            guard rpcAddressUpdated else {
                showError(desc: "Unable to update RPC address.")
                
                return
            }
            
            if rpcAddress.hasSuffix(".onion") {
                torEnabled = true
            } else {
                torEnabled = false
                torManager.resign()
                torConnected = false
                torProgress = 0.0
                
            }
        }
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
            showError(desc: "Invalid mnemonic.")
            
            return
        }
        
        guard let encSeed = Crypto.encrypt(encSigner.data(using: .utf8)!) else {
            showError(desc: "Unable to encrypt seed.")
            
            return
        }
        
        let dict: [String: Any] = ["encryptedData": encSeed]
        
        DataManager.saveEntity(entityName: "BIP39Signer", dict: dict) { saved in
            guard saved else {
                showError(desc: "Unable to save the encrypted signer.")
                
                return
            }
            
            encSigner = encSeed.hex
            showError(desc: "Signer encrypted and saved ✓")
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
                .foregroundStyle(.primary)
                                    
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
