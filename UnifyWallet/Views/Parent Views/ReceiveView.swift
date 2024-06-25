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
    
    
    var body: some View {
        Label("Receive", systemImage: "arrow.down.forward.circle")
        
        Form() {
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
                }
            }
            
            if let amountDouble = Double(amount), amountDouble > 0 && address != "" {
                NavigationLink {
                    ReceiveAddInputView(invoiceAmount: amountDouble, invoiceAddress: address)
                } label: {
                    Text("Add Inputs Manually")
                        .foregroundStyle(.blue)
                }
                
                Text("Select inputs manually to add to the Payjoin transaction.")
                    .foregroundStyle(.secondary)
                
                NavigationLink {
                    ReceiveAddOutputView(invoiceAmount: amountDouble, invoiceAddress: address, additionalInputs: [], utxos: utxos)
                } label: {
                    Text("Add Inputs Automatically")
                        .foregroundStyle(.blue)
                }
                
                Text("Bitcoin Core will use its coin selection algorithm to select inputs to pay the additonal output you specify.")
                    .foregroundStyle(.secondary)
                
                NavigationLink {
                    InvoiceView(invoiceAmount: amountDouble, invoiceAddress: address, additionalInputs: [], utxos: utxos, outputAddress: nil, outputAmount: nil)
                } label: {
                    Text("Skip")
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
            fetchAddress()
            getUtxos()
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
        let p = Get_New_Address(["address_type": "bech32"])
        
        BitcoinCoreRPC.shared.btcRPC(method: .getnewaddress(param: p)) { (response, errorDesc) in
            guard let address = response as? String else {
                displayError(desc: errorDesc ?? "Unknown error from getnewaddress.")
                
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
                
                return
            }
            
            guard response.count > 0 else {
                displayError(desc: "No utxo's.")
                
                return
            }
            
            for item in response {
                let utxo = Utxo(item)
                
                if let confs = utxo.confs, confs > 0,
                   let solvable = utxo.solvable, solvable {
                    utxos.append(utxo)
                }
            }
            
            if utxos.count == 0 {
                displayError(desc: "No spendable utxo's.")
            }
        }
    }
}





















