//
//  ReceiveView.swift
//  Pay Join
//
//  Created by Peter Denton on 2/14/24.
//


import SwiftUI


struct ReceiveView: View {
    @State private var amount = ""
    @State private var address = ""
    @State private var utxos: [Utxo] = []
    @State private var showError = false
    @State private var errDesc = ""
    @State private var torProgress = 0.0
    @State private var torEnabled = false
    @State private var showSpinner = false
    
    
    var body: some View {
        Form() {
            if torProgress < 100.0 && torEnabled {
                ProgressView("Tor bootstrapping \(Int(torProgress))% complete…", value: torProgress, total: 100)
            }
            
            Section("Create Invoice") {
                HStack() {
                    Label("Invoice amount", systemImage: "bitcoinsign.circle")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    TextField("", text: $amount)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                
                HStack() {
                    Label("Invoice address", systemImage: "arrow.down.forward.circle")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    TextField("", text: $address)
                        #if os(iOS)
                        .keyboardType(.default)
                        #endif
                        .autocorrectionDisabled()
                    
                    if showSpinner {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                }
            }
            
            if let amountDouble = Double(amount), amountDouble > 0 && address != "" {
                
                NavigationLink(value: ReceiveNavigationLinkValues.receiveAddOutputView(invoiceAmount: amountDouble, 
                                                                                       invoiceAddress: address,
                                                                                       utxos: utxos)) {
                    
                    Text("Add an output")
                        .foregroundStyle(.blue)
                }
                
                NavigationLink(value: ReceiveNavigationLinkValues.invoiceView(invoiceAmount: amountDouble, 
                                                                              invoiceAddress: address,
                                                                              additionalInputs: [],
                                                                              utxos: utxos,
                                                                              outputAddress: nil,
                                                                              outputAmount: nil)) {
                    Text("Skip adding an output")
                        .foregroundStyle(.blue)
                }
                
                Text("Payjoin transactions combine inputs and outputs from the sender and receiver, not adding inputs/output means this will be a standard transaction.")
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.bordered)
        .formStyle(.grouped)
        .multilineTextAlignment(.leading)
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
        .onAppear {
            amount = ""
            address = ""
            DataManager.retrieve(entityName: "RPCCredentials") { creds in
                guard let creds = creds else {
                    errDesc = "Looks like you are new here, go to Config to add the rpcauth to your bitcoin.conf and select a wallet."
                    showError = true
                    return
                }
                
                guard let address = creds["rpcAddress"] as? String else { return }
                
                if address.hasSuffix(".onion") {
                    torEnabled = UserDefaults.standard.object(forKey: "torEnabled") as? Bool ?? false
                    if torEnabled && TorClient.sharedInstance.state != .connected && TorClient.sharedInstance.state != .started {
                        TorClient.sharedInstance.start()
                    } else {
                        fetchAddress()
                        getUtxos()
                    }
                } else {
                    fetchAddress()
                    getUtxos()
                }
            }
            
            TorClient.sharedInstance.showProgress = { progress in
                torProgress = Double(progress)
            }
            
            TorClient.sharedInstance.torConnected = { connected in
                if connected {
                    fetchAddress()
                    getUtxos()
                }
            }
        }
        .alert(errDesc, isPresented: $showError) {
            Button("OK", role: .cancel) {}
        }
    }
    
    
    private func displayError(desc: String) {
        errDesc = desc
        showError = true
    }
    
    
    private func fetchAddress() {
        showSpinner = true
        let p = Get_New_Address(["address_type": "bech32"])
        
        BitcoinCoreRPC.shared.btcRPC(method: .getnewaddress(param: p)) { (response, errorDesc) in
            guard let address = response as? String else {
                displayError(desc: errorDesc ?? "Unknown error from getnewaddress.")
                showSpinner = false
                return
            }
            
            self.address = address
        }
    }
    
    
    private func getUtxos() {
        let p = List_Unspent([:])
        utxos.removeAll()
        
        BitcoinCoreRPC.shared.btcRPC(method: .listunspent(p)) { (response, errorDesc) in
            guard let response = response as? [[String: Any]] else {
                displayError(desc: errorDesc ?? "Unknown error from listunspent.")
                showSpinner = false
                return
            }
            
            guard response.count > 0 else {
                displayError(desc: "No utxo's.")
                showSpinner = false
                return
            }
            
            for item in response {
                let utxo = Utxo(item)
                
                if let confs = utxo.confs, confs > 0,
                   let solvable = utxo.solvable, solvable {
                    utxos.append(utxo)
                }
            }
            
            showSpinner = false
            
            if utxos.count == 0 {
                displayError(desc: "No spendable utxo's.")
            }
        }
    }
}





















