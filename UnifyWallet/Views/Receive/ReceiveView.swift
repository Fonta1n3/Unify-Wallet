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
    @State private var balance = 0.0
    @State private var fetchingBalance = false
    @State private var fetchingAddress = false
    @State private var isShowingScanner = false
    @FocusState var isInputActive: Bool
    
    
    var body: some View {
        Form() {
            if torProgress < 100.0 && torEnabled {
                HStack() {
                    ProgressView("Tor bootstrapping \(Int(torProgress))% complete…", value: torProgress, total: 100)
                    
                    ProgressView()
                        .padding(.leading)
                    #if os(macOS)
                        .scaleEffect(0.5)
                    #endif
                }
            }
            
            Section("Balance") {
                HStack() {
                    Label(balance.btcBalanceWithSpaces, systemImage: "bitcoinsign.circle")
                    
                    if fetchingBalance {
                        Spacer()
                        
                        ProgressView()
                        #if os(macOS)
                            .scaleEffect(0.5)
                        #endif
                    }
                }
                
            }
            
            Section("Create Invoice") {
                HStack() {
                    Label("Amount", systemImage: "bitcoinsign.circle")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    TextField("", text: $amount)
                        #if os(iOS)
                        .onSubmit {
                            isInputActive = false
                        }
                        .keyboardType(.decimalPad)
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
                    Label("Address", systemImage: "arrow.down.forward.circle")
                        .frame(maxWidth: 200, alignment: .leading)
                    
                    Spacer()
                    
                    TextField("", text: $address)
                        #if os(iOS)
                        .keyboardType(.default)
                        .onSubmit {
                            isInputActive = false
                        }
                        .keyboardType(.decimalPad)
                        .focused($isInputActive)
//                        .toolbar {
//                            ToolbarItemGroup(placement: .keyboard) {
//                                Spacer()
//                                
//                                Button("Done") {
//                                    isInputActive = false
//                                }
//                            }
//                        }
                        #endif
                        .autocorrectionDisabled()
                    
                    #if os(iOS)
                    Button {
                        isShowingScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                    }                    
                    .sheet(isPresented: $isShowingScanner) {
                        CodeScannerView(codeTypes: [.qr], simulatedData: "", completion: handleScan)
                    }
                    #endif
                    
                    if !fetchingAddress {
                        Button {
                            fetchAddress()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    
                    if fetchingAddress {
                        ProgressView()
                        #if os(macOS)
                            .scaleEffect(0.5)
                        #else
                            .padding(.leading)
                        #endif
                    }
                }
                
                if address != "" {
                    Text(address.withSpaces)
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
//        .onTapGesture{
//            isInputActive = false
//        }
        .buttonStyle(.bordered)
        .formStyle(.grouped)
        .multilineTextAlignment(.leading)
        .textFieldStyle(.roundedBorder)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
        .onAppear {
            amount = ""
            address = ""
            if TorClient.sharedInstance.state == .connected {
                torProgress = 100.0
            }
            DataManager.retrieve(entityName: "RPCCredentials") { creds in
                guard let creds = creds else {
                    //errDesc = "Looks like you are new here, go to Config to add the rpcauth to your bitcoin.conf and select a wallet."
                    //showError = true
                    return
                }
                
                guard let address = creds["rpcAddress"] as? String else { return }
                
                if address.hasPrefix("rarokrtgsiwy42pcgmrp2sds") {
                    errDesc = "You are using Unify in demo mode! This is a great way to test the app, navigate to Config and add your own credentials to get out of demo mode."
                    showError = true
                }
                
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
    
    
#if os(iOS)
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        switch result {
        case .success(let result):
            let invoice = Invoice(result.string)
            guard let address = invoice.address,
                  let amount = invoice.amount else {
                
                self.address = result.string
                
                return
            }
            
            self.address = address
            self.amount = "\(amount)"
            
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
#endif
    
    
    private func displayError(desc: String) {
        errDesc = desc
        showError = true
    }
    
    
    private func fetchAddress() {
        fetchingAddress = true
        let p = Get_New_Address(["address_type": "bech32"])
        
        BitcoinCoreRPC.shared.btcRPC(method: .getnewaddress(param: p)) { (response, errorDesc) in
            self.fetchingAddress = false
            
            guard let address = response as? String else {
                displayError(desc: errorDesc ?? "Unknown error from getnewaddress.")
                showSpinner = false
                return
            }
            
            self.address = address
        }
    }
    
    
    private func getUtxos() {
        fetchingBalance = true
        balance = 0.0
        let p = List_Unspent([:])
        utxos.removeAll()
        
        BitcoinCoreRPC.shared.btcRPC(method: .listunspent(p)) { (response, errorDesc) in
            fetchingBalance = false
            
            guard let response = response as? [[String: Any]] else {
                displayError(desc: errorDesc ?? "Unknown error from listunspent.")
                //showSpinner = false
                return
            }
            
            guard response.count > 0 else {
                displayError(desc: "No utxo's.")
                //showSpinner = false
                balance = 0.0
                return
            }
            
            for item in response {
                let utxo = Utxo(item)
                
                if let confs = utxo.confs, confs > 0,
                   let solvable = utxo.solvable, solvable {
                    utxos.append(utxo)
                    balance += utxo.amount!
                }
            }
            
            //showSpinner = false
            
            if utxos.count == 0 {
                displayError(desc: "No spendable utxo's.")
            }
        }
    }
}





















